"""Build and load C cases for the shared test runner."""

import copy
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

from ..compiler import (
    TEST_SUPPORT_C, ZCC, ZX_HOST_SOURCE, ZXTEST_SOURCE, file_digest, generate_vectors,
    map_symbol, parse_map, run_test_build,
)
from ..fixtures.images import prepare_images
from ..profiles import case_profile_names
from ..support import PAGE_SIZE, PROTOCOL_FILE, TEST_RUNNER, FrameworkError
from ..zx_host.manifest import LaunchConfig
from . import TestSuite


PROFILE_LIST_KEYS = {"cflags", "defines", "make_args", "make_targets", "extra_libs"}


def merge_profile_layer(target, layer):
    for key, value in layer.items():
        if key in {"description", "parent"}:
            continue
        if isinstance(value, dict):
            nested = target.setdefault(key, {})
            if not isinstance(nested, dict):
                raise FrameworkError(f"cannot merge profile field {key!r}: expected an object")
            merge_profile_layer(nested, value)
        elif key in PROFILE_LIST_KEYS and isinstance(value, list):
            current = target.setdefault(key, [])
            if not isinstance(current, list):
                raise FrameworkError(f"cannot merge profile field {key!r}: expected a list")
            for item in value:
                if item not in current:
                    current.append(item)
        else:
            target[key] = copy.deepcopy(value)


def profile_assignment(key, option):
    if key == "make_args":
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", option)
        return ("make", match.group(1), match.group(2)) if match else None
    if key == "defines":
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)(?:=(.*))?$", option)
        return ("define", match.group(1), match.group(2) or "1") if match else None
    if key == "cflags":
        match = re.match(r"^-pragma-define:([^=]+)=(.*)$", option)
        if match:
            return ("pragma", match.group(1), match.group(2))
        match = re.match(r"^-D([^=]+)(?:=(.*))?$", option)
        if match:
            return ("define", match.group(1), match.group(2) or "1")
    return None


def validate_profile_options(profile):
    assignments = {}
    for key in ("cflags", "defines"):
        for option in profile.get(key, []):
            assignment = profile_assignment(key, option)
            if assignment:
                namespace, name, value = assignment
                identity = (namespace, name)
                previous = assignments.get(identity)
                if previous is not None and previous != value:
                    raise FrameworkError(
                        f"conflicting profile settings for {name}: {previous!r} and {value!r}"
                    )
                assignments[identity] = value
    for option in profile.get("library", {}).get("make_args", []):
        assignment = profile_assignment("make_args", option)
        if assignment:
            namespace, name, value = assignment
            identity = (namespace, name)
            previous = assignments.get(identity)
            if previous is not None and previous != value:
                raise FrameworkError(
                    f"conflicting profile settings for {name}: {previous!r} and {value!r}"
                )
            assignments[identity] = value


def layout_values(layout):
    values = {
        "code_org": int(layout["code_org"]),
        "data_org": int(layout["data_org"]),
        "bss_org": int(layout["bss_org"]),
        "stack_org": int(layout["stack_org"]),
        "code_page": int(layout["code_page"]),
        "code_window": int(layout.get("code_window", 0)),
        "data_page": int(layout["data_page"]),
    }
    if not 0 <= values["code_window"] <= 3:
        raise FrameworkError("profile layout.code_window must be in 0..3")
    return values


class CTestSuite(TestSuite):
    """Compile SDK library cases with a machine-specific mapper."""

    default_profile = "default"

    def merge_profile(self, layers):
        profile = {}
        for layer in layers.values():
            merge_profile_layer(profile, layer)
        validate_profile_options(profile)
        return profile

    def updates_shared_expectations(self, meta, profile):
        names = case_profile_names(meta, default=self.default_profile)
        return not self.case_prefix and profile["name"] == names[0]

    def build_target(self, profile, verbose):
        """Prepare the target library and return its compiler configuration."""
        raise NotImplementedError

    def page_write(self, window, page):
        """Return the port and value that map a physical RAM page."""
        raise NotImplementedError

    def launch_ports(self, profile, layout):
        """Return the initialization writes before loading the RAM blocks."""
        raise NotImplementedError

    def build_fingerprint(self, case_path, profile, case_sources, target, romfile):
        digest = hashlib.sha256()
        parts = [*case_sources, case_path.with_suffix(".toml"), self.profiles_file,
                 Path(__file__), PROTOCOL_FILE, ZX_HOST_SOURCE, ZXTEST_SOURCE,
                 TEST_SUPPORT_C / "zx_host.h", TEST_SUPPORT_C / "zx_test.h",
                 *target.sources, *target.inputs]
        if romfile:
            parts.append(romfile)
        for path in parts:
            digest.update(str(path).encode())
            if path.is_file():
                digest.update(file_digest(path).encode())
        digest.update(json.dumps(profile, sort_keys=True).encode())
        digest.update(ZCC.encode())
        return digest.hexdigest()

    def block(self, name, address, page, window, category, filename, length):
        port, value = self.page_write(window, page)
        return {
            "name": name,
            "address": address,
            "physical_page": page,
            "window": window,
            "port": port,
            "raw_page": value,
            "category": category,
            "filename": filename,
            "length": length,
        }

    def compile_case(self, case_path, meta, profile, verbose=False):
        emulator_args = meta.get("emulator_args", [])
        if not isinstance(emulator_args, list) or any(not isinstance(arg, str) for arg in emulator_args):
            raise FrameworkError("case emulator_args must be a list of strings")
        test_rom = os.environ.get("ZXEVO_TEST_ROM") if profile.get("use_test_rom") else None
        romfile = Path(test_rom).resolve() if test_rom else None
        if romfile and not romfile.is_file():
            raise FrameworkError(f"test ROM is missing: {romfile}")
        layout = layout_values(profile["layout"])
        case_name = case_path.stem
        case_relative = self.case_relative_path(case_path)
        out_dir = self.run_directory(case_relative, profile)
        out_dir.mkdir(parents=True, exist_ok=True)
        binary = out_dir / case_name
        map_path = binary.with_suffix(".map")

        sources = [case_path]
        for extra in meta.get("sources", []):
            sources.append((case_path.parent / extra).resolve())
        case_sources = list(sources)
        emulator_images = prepare_images(out_dir / "emulator_images", meta.get("emulator_images", {}))
        if emulator_images:
            case_sources.append(TEST_RUNNER / "fixtures" / "images.py")

        target = self.build_target(profile, verbose)
        fingerprint = self.build_fingerprint(case_path, profile, case_sources, target, romfile)
        stamp = out_dir / "stamp"
        manifest_path = out_dir / "manifest.json"
        if not (stamp.is_file() and stamp.read_text() == fingerprint + "\n" and manifest_path.is_file()):
            generated_header = out_dir / "zx_host_config.h"
            subprocess.run(
                [sys.executable, str(TEST_RUNNER / "zx_host" / "generate_header.py"),
                 str(PROTOCOL_FILE), str(generated_header)],
                check=True, capture_output=True, text=True)
            command = [
                ZCC,
                *target.flags,
                "-clib=classic",
                "-compiler=sdcc",
                "--reserve-regs-iy",
                "-SO3",
                "-m",
                f"-I{TEST_SUPPORT_C}",
                f"-I{out_dir}",
                f"-I{self.cases}",
                f"-pragma-define:CRT_MODEL=0",
                f"-pragma-define:MMAP=-1",
                f"-pragma-define:CRT_ORG_CODE=0x{layout['code_org']:X}",
                f"-pragma-define:CRT_ORG_DATA=0x{layout['data_org']:X}",
                f"-pragma-define:CRT_ORG_BSS=0x{layout['bss_org']:X}",
                f"-pragma-define:REGISTER_SP=0x{layout['stack_org']:X}",
            ]
            command.extend(profile.get("cflags", []))
            command.extend(f"-D{value}" for value in profile.get("defines", []))
            command.extend(f"-D{value}" for value in meta.get("defines", []))
            command.extend(meta.get("cflags", []))
            command.extend(f"-l{name}" for name in profile.get("library", {}).get("extra_libs", []))
            command.append("-o")
            command.append(str(binary))
            command.extend(str(path) for path in sources)
            command.extend(str(path) for path in (*target.sources, ZXTEST_SOURCE, ZX_HOST_SOURCE))
            if verbose:
                print("  " + " ".join(command))
            result = run_test_build(command, crash_log=out_dir / "build.sigsegv.log",
                                    env={**os.environ, **target.env})
            (out_dir / "build.log").write_text(result.stdout + result.stderr, encoding="utf-8")
            if result.returncode != 0:
                tail = (result.stdout + result.stderr).strip().splitlines()[-15:]
                raise FrameworkError("compile failed:\n" + "\n".join(tail))
            if not map_path.is_file():
                raise FrameworkError(f"compiler did not produce {map_path.name}")

            symbols = parse_map(map_path)
            code_org = map_symbol(symbols, "start")
            rodata_end = symbols.get("__RODATA_END_head", symbols.get("__CODE_END_tail"))
            data_org = map_symbol(symbols, "__DATA_head")
            data_end = map_symbol(symbols, "__DATA_END_tail")
            bss_org = map_symbol(symbols, "__BSS_head")
            bss_end = map_symbol(symbols, "__BSS_END_tail")
            stack = map_symbol(symbols, "__register_sp")
            if code_org != layout["code_org"]:
                raise FrameworkError(f"start symbol is 0x{code_org:04X}, expected 0x{layout['code_org']:04X}")
            if data_org != layout["data_org"] or bss_org != layout["bss_org"]:
                raise FrameworkError("linked DATA/BSS addresses do not match the profile layout")
            if stack != layout["stack_org"]:
                raise FrameworkError("linked stack does not match the profile layout")
            protocol = json.loads(PROTOCOL_FILE.read_text(encoding="utf-8"))
            code_window = layout["code_window"]
            code_window_end = (code_window + 1) * PAGE_SIZE
            if code_window == 0 and rodata_end > protocol["header_address"]:
                raise FrameworkError(
                    f"test is too large: code+rodata ends at 0x{rodata_end:04X}, "
                    f"the ZXHost mailbox starts at 0x{protocol['header_address']:04X}")
            if code_window != 0 and rodata_end > code_window_end:
                raise FrameworkError(
                    f"code+rodata ends at 0x{rodata_end:04X}, past W{code_window} end "
                    f"0x{code_window_end:04X}")
            if code_window != 0 and layout["stack_org"] <= rodata_end:
                raise FrameworkError("stack overlaps code+rodata in the test code window")
            log_end = protocol["log_address"] + protocol["log_size"]
            if layout["data_org"] < log_end:
                raise FrameworkError(
                    f"DATA starts at 0x{layout['data_org']:04X}, inside the ZXHost log ending at 0x{log_end:04X}")
            if data_end > bss_org:
                raise FrameworkError(f"DATA ends at 0x{data_end:04X}, past BSS at 0x{bss_org:04X}")
            if bss_end + 0x400 > stack:
                raise FrameworkError(f"BSS ends at 0x{bss_end:04X}, too close to the stack at 0x{stack:04X}")
            if log_end > stack:
                raise FrameworkError("ZXHost log overlaps the stack")

            code_data = binary.read_bytes()
            expected_length = rodata_end - layout["code_org"]
            if len(code_data) != expected_length:
                raise FrameworkError(
                    f"code image is {len(code_data)} bytes, map says {expected_length}; "
                    "the link layout is inconsistent")
            split = PAGE_SIZE - layout["code_org"] if code_window == 0 else len(code_data)
            code0 = out_dir / "code0.bin"
            code0.write_bytes(code_data[:split])
            blocks = []
            if code_window == 0:
                generate_vectors(out_dir / "vectors.bin")
                blocks.append(self.block("VECTORS", 0, layout["code_page"], 0,
                                         "vectors", "vectors.bin", 256))
            blocks.append(self.block("CODE", layout["code_org"], layout["code_page"], code_window,
                                     "code", code0.name, len(code_data[:split])))
            if code_window == 0 and len(code_data) > split:
                code1 = out_dir / "code1.bin"
                code1.write_bytes(code_data[split:])
                blocks.append(self.block("CODE1", PAGE_SIZE, layout["data_page"], 1,
                                         "code", code1.name, len(code_data) - split))
            data_bin = binary.with_name(binary.name + "_DATA.bin")
            if data_bin.is_file() and data_bin.stat().st_size:
                data_len = data_bin.stat().st_size
                if data_len != data_end - data_org:
                    raise FrameworkError("DATA image size does not match the map")
                blocks.append(self.block("DATA", data_org, layout["data_page"], 1,
                                         "data", data_bin.name, data_len))
            launch = LaunchConfig(profile.get("boot_cycles", 500_000),
                                  tuple(self.launch_ports(profile, layout)), profile.get("boot_pc"))
            manifest = {
                "protocol": protocol,
                "machine": self.machine,
                "launch": launch.to_dict(),
                "entry": layout["code_org"],
                "stack": layout["stack_org"],
                "blocks": blocks,
            }
            if romfile:
                manifest["romfile"] = str(romfile)
            if emulator_args:
                manifest["emulator_args"] = emulator_args
            if emulator_images:
                manifest["emulator_images"] = {
                    device: path.relative_to(out_dir).as_posix()
                    for device, path in emulator_images.items()
                }
            manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
            stamp.write_text(fingerprint + "\n", encoding="utf-8")
        return manifest_path, binary.stat().st_size
