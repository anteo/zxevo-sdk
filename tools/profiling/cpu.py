#!/usr/bin/env python3
"""Measure one Z80 function and selected calls in a TAP using ZEsarUX."""

import argparse
from collections import defaultdict
import json
from pathlib import Path
import re
import socket
import tempfile

from tools.zesarux.runner import ZesaruxRunner, breakpoint, default_emulator, registers, return_site
from tools.zesarux.tap_runner import cpu_speed, run_to_tap_entry, send_key_script


def function_addresses(path, names):
    addresses = defaultdict(set)
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^(\S+)\s*=\s*\$([0-9A-Fa-f]+)\s*;\s*addr,", line)
        if match:
            name, address = match.groups()
            addresses[name].add(int(address, 16))

    resolved = []
    for name in names:
        matches = addresses.get(name) or addresses.get("_" + name)
        if not matches:
            raise ValueError(f"{path} has no address for {name!r}")
        if len(matches) != 1:
            raise ValueError(f"{path} has multiple addresses for {name!r}")
        resolved.append(next(iter(matches)))
    if len(set(resolved)) != len(resolved):
        raise ValueError("the entry and profiled functions must have distinct addresses")
    return resolved


def measure(remote, args, entry, functions):
    remote.enter_cpu_step()
    remote.run_cycles(2_000_000)
    send_key_script(remote, args.keys, 120_000, 100_000)

    sp = run_to_tap_entry(remote, entry, args.instructions)
    exit_site = return_site(remote, sp)
    breakpoint(remote, 1, *exit_site)
    for index, address in enumerate(functions, 3):
        breakpoint(remote, index, address)

    clock = cpu_speed(remote)
    remote.command("reset-tstates-partial")
    calls = {name: [] for name in functions.values()}
    for _ in range(10_000):
        remote.run_cycles(args.instructions)
        pc, sp = registers(remote)
        if (pc, sp) == exit_site:
            break
        if pc not in functions:
            raise RuntimeError(f"no profiling breakpoint reached, stopped at ${pc:04X}")

        end = return_site(remote, sp)
        # Measure this call inclusively. Selected callees inside it are part
        # of its cost, so function totals never double-count the same time.
        for index in range(3, 3 + len(functions)):
            remote.command(f"disable-breakpoint {index}")
        breakpoint(remote, 2, *end)
        start = remote.get_partial_tstates()
        remote.run_cycles(args.instructions)
        if registers(remote) != end:
            raise RuntimeError(f"{functions[pc]} did not return to ${end[0]:04X}")
        calls[functions[pc]].append({"return": f"0x{end[0]:04x}",
                                     "tstates": remote.get_partial_tstates() - start})
        remote.command("disable-breakpoint 2")
        if end == exit_site:
            break
        for index in range(3, 3 + len(functions)):
            remote.command(f"enable-breakpoint {index}")
    else:
        raise RuntimeError("entry did not return within 10,000 profiled calls")

    return {"tap": str(args.tap), "machine": args.machine, "cpu_hz_at_entry": clock,
            "entry": args.entry, "tstates": remote.get_partial_tstates(), "calls": calls}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tap", required=True, type=Path)
    parser.add_argument("--map", type=Path, help="linker map, defaults to the TAP's sibling .map")
    parser.add_argument("--entry", required=True, help="function that bounds the measured region")
    parser.add_argument("--functions", nargs="+", default=[], help="functions to time within the entry")
    parser.add_argument("--zesarux", default=default_emulator())
    parser.add_argument("--machine", default="BaseConf")
    parser.add_argument("--rom", type=Path, help="custom ROM to load in ZEsarUX")
    parser.add_argument("--keys", default="i;w8;load;quote;quote",
                        help="BASIC startup and loader keys before the final Enter")
    parser.add_argument("--instructions", type=int, default=3_000_000,
                        help="maximum instructions between profiling breakpoints")
    parser.add_argument("--output", type=Path, help="write per-call timings to a JSON file")
    args = parser.parse_args()
    args.tap = args.tap.resolve()
    if not args.tap.is_file():
        parser.error(f"TAP does not exist: {args.tap}")
    if len(args.functions) > 98 or args.instructions < 1:
        parser.error("supply at most 98 functions and a positive instruction limit")

    try:
        entry, *addresses = function_addresses(args.map or args.tap.with_suffix(".map"),
                                               [args.entry, *args.functions])
        functions = dict(zip(addresses, args.functions))
        extra_args = ["--hardware-debug-ports", "--realvideo", "--noautoload", "--tape", str(args.tap)]
        if args.rom:
            extra_args.extend(("--romfile", str(args.rom.resolve())))
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        with tempfile.TemporaryDirectory(prefix="zx-tap-profile-") as directory:
            with ZesaruxRunner(args.zesarux, machine=args.machine, port=port, extra_args=extra_args,
                               log_path=Path(directory) / "zesarux.log") as runner:
                result = measure(runner.remote, args, entry, functions)
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, RuntimeError) as exc:
        parser.exit(1, f"Profiling failed: {exc}\n")

    elapsed = result["tstates"]
    print(f"{args.entry}  {elapsed:,} T-states  (CPU clock at entry {result['cpu_hz_at_entry']} Hz)")
    if functions:
        totals = [(sum(call["tstates"] for call in calls), len(calls), name)
                  for name, calls in result["calls"].items()]
        print(f"{'Function':<32} {'Calls':>7} {'T-states':>14} {'Share':>8}")
        for total, count, name in sorted(totals, reverse=True):
            share = total / elapsed if elapsed else 0
            print(f"{name:<32} {count:>7} {total:>14,} {share:>8.1%}")
        print(f"{'Other':<32} {'':>7} {elapsed - sum(row[0] for row in totals):>14,}")


if __name__ == "__main__":
    main()
