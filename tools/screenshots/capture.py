#!/usr/bin/env python3
"""Load a BASIC 48 TAP or TSConf SPG in ZEsarUX and capture its screen as PNG."""

import argparse
import socket
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.zesarux.runner import ZesaruxRunner, default_emulator, registers
from tools.zesarux.tap_runner import run_to_tap_entry, send_key_script


def run_instructions(remote, count):
    """Keep each ZRCP run bounded while advancing the requested opcode count."""
    while count:
        chunk = min(count, 500_000)
        remote.run_cycles(chunk)
        count -= chunk


def start_basic(remote, args):
    if args.machine == "TSConf":
        # BASIC 48 ROM page 3, uncached RAM in W1/W2/W3, DOS disabled,
        # and only the frame interrupt enabled.
        for address, value in ((0x00AF, 0x20), (0x10AF, 3), (0x11AF, 5),
                               (0x12AF, 2), (0x13AF, 0), (0x15AF, 0),
                               (0x20AF, 0), (0x21AF, 4), (0x2AAF, 1)):
            remote.write_port(address, value)
        remote.set_register("PC=0")
    run_instructions(remote, args.boot_instructions)
    startup = args.startup_keys
    if startup is None:
        startup = "i;w8" if args.machine == "BaseConf" else ""
    send_key_script(remote, startup, args.key_instructions, args.key_settle_instructions)


def capture(args):
    args.output.parent.mkdir(parents=True, exist_ok=True)
    extra = ["--hardware-debug-ports", "--realvideo", "--noautoload"]
    if args.tap:
        extra.extend(("--tape", str(args.tap)))
    if args.rom:
        extra.extend(("--romfile", str(args.rom.resolve())))
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]
    with ZesaruxRunner(args.zesarux, machine=args.machine, port=port,
                       extra_args=extra, log_path=args.log) as runner:
        remote = runner.remote
        remote.enter_cpu_step()
        if args.spg:
            # Use the emulator's real SPG loader, including compressed banks
            # and initial machine state, rather than emulating the file format.
            quoted = str(args.spg).replace('"', '\\"')
            response = remote.command(f'smartload "{quoted}"')
            if "ERROR" in response.upper():
                raise RuntimeError(response.strip())
            if registers(remote)[0] != args.entry:
                raise RuntimeError("SPG loader did not set the header entry address")
        else:
            start_basic(remote, args)
            send_key_script(remote, args.load_keys,
                            args.key_instructions, args.key_settle_instructions)
            run_to_tap_entry(remote, args.entry, args.load_instructions)
            remote.command("disable-breakpoints")
        run_instructions(remote, args.instructions)
        if args.keys:
            send_key_script(remote, args.keys,
                            args.key_instructions, args.key_settle_instructions)
            run_instructions(remote, args.after_key_instructions)
        remote.save_screen(args.output)
    print(f"Screenshot: {args.output}")
    print(f"Emulator log: {args.log}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--tap", type=Path, help="built BASIC 48 TAP to load")
    source.add_argument("--spg", type=Path, help="TSConf SPG to load through ZEsarUX smartload")
    parser.add_argument("--output", required=True, type=Path, help="destination PNG")
    parser.add_argument("--machine", choices=("TSConf", "BaseConf", "48K"), default="TSConf")
    parser.add_argument("--entry", type=lambda value: int(value, 0),
                        help="TAP CPU entry address, default 0x8000; SPG uses its header")
    parser.add_argument("--instructions", type=int, default=6_000_000,
                        help="opcodes after entry, before application keys or capture")
    parser.add_argument("--keys", default="", help="application keys, e.g. 'enter;h;e;l;l;o'")
    parser.add_argument("--after-key-instructions", type=int, default=500_000)
    parser.add_argument("--boot-instructions", type=int, default=2_000_000)
    parser.add_argument("--load-instructions", type=int, default=2_000_000,
                        help="instruction budget to reach the TAP entry after Enter")
    parser.add_argument("--startup-keys", help="override ROM startup keys; BaseConf defaults to 'i;w8'")
    parser.add_argument("--load-keys", default="load;quote;quote",
                        help="BASIC loader keys BEFORE the final Enter, which is sent automatically")
    parser.add_argument("--key-instructions", type=int, default=50_000)
    parser.add_argument("--key-settle-instructions", type=int, default=50_000)
    parser.add_argument("--zesarux", default=default_emulator())
    parser.add_argument("--rom", type=Path, help="optional ROM for the selected machine")
    parser.add_argument("--log", type=Path, help="default: build/screenshots/<input-name>.log")
    args = parser.parse_args()
    if args.spg and (args.machine != "TSConf" or args.entry is not None):
        parser.error("--spg requires --machine TSConf and uses the entry address from its header")
    input_path = (args.tap or args.spg).resolve()
    if args.tap:
        args.tap = input_path
    else:
        args.spg = input_path
    args.output = args.output.resolve()
    args.log = (args.log or Path("build/screenshots") / f"{input_path.stem}.log").resolve()
    if not input_path.is_file():
        parser.error(f"input does not exist: {input_path}")
    if args.spg:
        try:
            with args.spg.open("rb") as source_file:
                header = source_file.read(1024)
        except OSError as error:
            parser.error(str(error))
        if len(header) != 1024 or header[0x20:0x2c] != b"SpectrumProg" or header[0x2c] != 0x10:
            parser.error("--spg requires a SpectrumProg 1.0 header supported by the capture workflow")
        args.entry = int.from_bytes(header[0x30:0x32], "little")
    elif args.entry is None:
        args.entry = 0x8000
    if args.output.suffix.lower() != ".png":
        parser.error("--output must name a .png file")
    if not 0 <= args.entry <= 0xffff:
        parser.error("--entry must be a CPU address in 0..65535")
    for name, value in vars(args).items():
        if name.endswith("instructions") and value < 0:
            parser.error(f"--{name.replace('_', '-')} must be nonnegative")
    if args.key_instructions == 0 or args.key_settle_instructions == 0:
        parser.error("key instruction counts must be positive")
    if len({input_path, args.output, args.log}) != 3:
        parser.error("input, output and log paths must be distinct")
    try:
        capture(args)
    except (OSError, ValueError, RuntimeError) as error:
        parser.exit(1, f"Screenshot capture failed: {error}\nEmulator log: {args.log}\n")


if __name__ == "__main__":
    main()
