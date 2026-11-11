#!/usr/bin/env python3
"""Measure font draw loops in ZEsarUX using its partial T-state counter."""
import argparse
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools" / "zesarux"))
from runner import ZesaruxRunner, default_emulator, keyboard_matrix  # noqa: E402
from tap_runner import KEYS, send_key_script  # noqa: E402


def map_symbol(path, name):
    pattern = re.compile(rf"_{re.escape(name)}\s*=\s*\$([0-9A-Fa-f]+)")
    with open(path, encoding="utf-8") as source:
        for line in source:
            match = pattern.search(line)
            if match:
                return int(match.group(1), 16)
    raise RuntimeError(f"symbol not found in map: {name}")


def register_pc(remote):
    match = re.search(r"\bPC=([0-9A-Fa-f]+)", remote.command("get-registers"))
    if not match:
        raise RuntimeError("ZEsarUX did not report PC")
    return int(match.group(1), 16)


def run_to(remote, address, label):
    remote.run_cycles(50_000_000)
    pc = register_pc(remote)
    if pc != address:
        registers = remote.command("get-registers")
        breakpoints = remote.command("get-breakpoints")
        raise RuntimeError(
            f"expected {label} at ${address:04X}, stopped at ${pc:04X}; "
            f"registers={registers!r}; breakpoints={breakpoints!r}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tap", required=True)
    parser.add_argument("--map", required=True)
    parser.add_argument("--mode", type=int, choices=(0, 4), default=0)
    parser.add_argument("--output", required=True)
    parser.add_argument("--port", type=int, default=10111)
    args = parser.parse_args()

    symbol_names = ["font5_bench_start", "font5_bench_done"]
    if args.mode != 4:
        symbol_names.extend(("font8_bench_start", "font8_bench_done"))
    symbols = {name: map_symbol(args.map, name) for name in symbol_names}
    runner = ZesaruxRunner(
        default_emulator(), machine="BaseConf", port=args.port,
        video_output="null", audio_output="null",
        extra_args=["--hardware-debug-ports", "--realvideo", "--tape",
                    os.path.abspath(args.tap)],
        quickexit=False)
    try:
        runner.start()
        remote = runner.remote
        remote.enter_cpu_step()
        remote.run_cycles(2_000_000)
        send_key_script(remote, "i;w40;load;quote;quote", 50_000, 50_000)
        remote.command("enable-breakpoints")
        for index, name in enumerate(symbols, 1):
            address = symbols[name]
            remote.command(f"set-breakpoint {index} PC={address:04X}H")
            remote.command(f"set-breakpointaction {index} break")
        remote.command("set-ui-io-ports " + keyboard_matrix(KEYS["enter"]))
        remote.run_cycles(50_000)
        remote.command("set-ui-io-ports " + keyboard_matrix([]))
        start5 = symbols["font5_bench_start"]
        pc = register_pc(remote)
        if pc != start5:
            raise RuntimeError(
                f"TAP load did not stop at the font5 benchmark entry: "
                f"expected ${start5:04X}, got ${pc:04X}; "
                f"registers={remote.command('get-registers')!r}")

        measurements = {}
        stages = ((1, "font5"),) if args.mode == 4 else ((1, "font5"), (3, "font8"))
        for index, prefix in stages:
            start = symbols[f"{prefix}_bench_start"]
            done = symbols[f"{prefix}_bench_done"]
            if prefix == "font8":
                run_to(remote, start, prefix + " start")
            remote.command("reset-tstates-partial")
            remote.command(f"disable-breakpoint {index}")
            run_to(remote, done, prefix + " done")
            elapsed = remote.get_partial_tstates()
            measurements[prefix] = {
                "tstates": elapsed,
                "glyphs": 64,
                "tstates_per_glyph": elapsed / 64,
            }
        result = {
            "emulator": "ZEsarUX",
            "machine": "BaseConf / ATM 640" if args.mode == 4 else "BaseConf / ZX 256",
            "tap": os.path.abspath(args.tap),
            "measurements": measurements,
        }
        os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as output:
            json.dump(result, output, indent=2)
            output.write("\n")
        print(json.dumps(result, indent=2))
    finally:
        runner.close()
        if runner.process is not None:
            runner.process.terminate()


if __name__ == "__main__":
    main()
