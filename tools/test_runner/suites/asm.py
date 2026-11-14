"""Assemble sjasmplus cases and prepare their emulator manifests."""

import json
import os
import re
import shlex
import subprocess

from ..support import PAGE_SIZE, PROTOCOL_FILE, TEST_SUPPORT, FrameworkError
from ..zx_host.generate_header import generate_header
from ..zx_host.manifest import BlockRecord, LaunchConfig, ZXHostManifestBuilder
from . import TestSuite


class AsmTestSuite(TestSuite):
    case_source_pattern = "main.asm"

    def __init__(self, tests, build_dir, rom, rom_symbols=None, *, sjasmplus="sjasmplus", include_dirs=()):
        super().__init__(tests, None)
        self.build_dir = build_dir.resolve()
        self.rom = rom.resolve()
        self.rom_symbols = rom_symbols
        self.sjasmplus = os.path.abspath(sjasmplus) if os.path.dirname(sjasmplus) else sjasmplus
        self.include_dirs = tuple(directory.resolve() for directory in include_dirs)

    def case_relative_path(self, path):
        return path.parent.relative_to(self.cases)

    def merge_profile(self, layers):
        profile = {}
        layout = {}
        ports = []
        machines = set()
        for name, layer in layers.items():
            if "machine" in layer:
                machine = layer["machine"]
                if not isinstance(machine, str) or not machine.strip():
                    raise FrameworkError(f"ASM profile {name!r}: machine must be a nonempty string")
                machines.add(machine)
            profile.update(layer)
            layout.update(layer.get("layout", {}))
            ports.extend(layer.get("ports", []))
        if not machines:
            raise FrameworkError("ASM profiles must specify a ZEsarUX machine")
        if len(machines) > 1:
            raise FrameworkError(f"cannot combine ASM profiles for different machines: {', '.join(sorted(machines))}")
        profile.pop("parent", None)
        return dict(profile, layout=layout, ports=ports)

    def assemble(self, source, binary, log_path, verbose):
        source = source.resolve()
        include_dirs = (binary.parent, TEST_SUPPORT / "z80", *self.include_dirs, source.parent)
        command = [self.sjasmplus, *(f"--inc={directory}" for directory in include_dirs),
                   f"--raw={binary.name}", str(source)]
        if verbose:
            print(f"\n  {shlex.join(command)}", flush=True)
        result = subprocess.run(command, cwd=binary.parent, capture_output=True,
                                text=True, errors="replace")
        diagnostics = result.stdout + result.stderr
        log_path.write_text(diagnostics, encoding="utf-8")
        if result.returncode:
            tail = "\n".join(diagnostics.strip().splitlines()[-15:])
            raise FrameworkError(f"{source.name}: sjasmplus exited with {result.returncode}\n{tail}\nSee {log_path}")

    def patched_rom(self, patch, case_path, output, verbose):
        """Apply the case's binary replacement at a bank-local assembly symbol."""
        if self.rom_symbols is None:
            raise FrameworkError("rom_patch requires --rom-symbols")
        bank = patch.get("bank")
        symbol = patch.get("symbol")
        filename = patch.get("file")
        source = patch.get("source")
        if (type(bank) is not int or bank < 0 or not isinstance(symbol, str)
                or (filename is None) == (source is None)
                or not isinstance(source if filename is None else filename, str)):
            raise FrameworkError("rom_patch requires bank, symbol and either source or file")
        match = re.search(rf"^{re.escape(symbol)}:[ \t]+EQU[ \t]+0x([0-9a-f]+)\b",
                          self.rom_symbols.read_text(), re.IGNORECASE | re.MULTILINE)
        if match is None:
            raise FrameworkError(f"{symbol} is missing from {self.rom_symbols}")
        offset = int(match[1], 16)
        if source is not None:
            binary = output / "rom-patch.bin"
            self.assemble(case_path.parent / source, binary, output / "rom-patch.log", verbose)
        else:
            binary = output.parent / filename
        replacement = binary.read_bytes()
        rom = bytearray(self.rom.read_bytes())
        if bank >= len(rom) // PAGE_SIZE or not replacement or offset + len(replacement) > PAGE_SIZE:
            raise FrameworkError(f"replacement at {symbol} does not fit in ROM bank {bank:#x}")
        start = bank * PAGE_SIZE + offset
        rom[start:start + len(replacement)] = replacement
        patched = output / "test.rom"
        if patched.resolve() == self.rom:
            raise FrameworkError("the test ROM output must differ from the source ROM")
        patched.write_bytes(rom)
        return patched.resolve()

    def compile_case(self, case_path, meta, profile, verbose=False):
        relative_case = self.case_relative_path(case_path)
        output = self.run_directory(relative_case, profile)
        binary = output / "test.bin"
        manifest_path = output / "manifest.json"
        layout = profile["layout"]
        code_org = layout["code_org"]
        stack_org = layout["stack_org"]
        machine_name = profile["machine"]
        launch = LaunchConfig(profile["boot_cycles"], tuple(profile["ports"]), profile.get("boot_pc"))

        try:
            if not self.rom.is_file():
                raise FrameworkError(f"test ROM is missing: {self.rom}")
            protocol = json.loads(PROTOCOL_FILE.read_text(encoding="utf-8"))
            manifest_path.unlink(missing_ok=True)
            generate_header(protocol, output / "zx_host_config.inc", "sjasmplus")
            self.assemble(case_path, binary, output / "build.log", verbose)
            size = binary.stat().st_size
            if not 0 < size <= stack_org - code_org - 0x100:
                raise FrameworkError(f"{binary}: empty binary or insufficient space for the stack")
            builder = ZXHostManifestBuilder(protocol, machine_name, launch, code_org, stack_org)
            builder.add_block(BlockRecord("CODE", code_org, layout["code_page"],
                                          code_org // PAGE_SIZE, layout["code_port"],
                                          layout["code_value"], "code", binary.name, size))
            manifest = builder.build().to_dict()
            rom = self.rom
            if "rom_patch" in meta:
                rom = self.patched_rom(meta["rom_patch"], case_path, output, verbose)
            manifest["romfile"] = str(rom)
            manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        except (OSError, ValueError) as error:
            raise FrameworkError(str(error)) from error
        return manifest_path, size
