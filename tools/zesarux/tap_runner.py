#!/usr/bin/env python3
"""Load a TAP through ZRCP and save emulator diagnostics."""
import argparse
import os
import sys

try:
    from .runner import ZesaruxRunner, breakpoint, default_emulator, keyboard_matrix, registers
except ImportError:
    from runner import ZesaruxRunner, breakpoint, default_emulator, keyboard_matrix, registers


KEYS = {
    "caps": [(0, 0)],
    "sym": [(7, 1)],
    "space": [(7, 0)],
    "enter": [(6, 0)],
    "up": [(0, 0), (4, 3)],
    "down": [(0, 0), (4, 4)],
    "left": [(0, 0), (4, 1)],
    "right": [(0, 0), (4, 2)],
    "load": [(6, 3)],
    "quote": [(7, 1), (5, 0)],
    "break": [(0, 0), (7, 0)],
}
KEYS.update({
    "z": [(0, 1)], "x": [(0, 2)], "c": [(0, 3)], "v": [(0, 4)],
    "a": [(1, 0)], "s": [(1, 1)], "d": [(1, 2)], "f": [(1, 3)], "g": [(1, 4)],
    "q": [(2, 0)], "w": [(2, 1)], "e": [(2, 2)], "r": [(2, 3)], "t": [(2, 4)],
    "1": [(3, 0)], "2": [(3, 1)], "3": [(3, 2)], "4": [(3, 3)], "5": [(3, 4)],
    "0": [(4, 0)], "9": [(4, 1)], "8": [(4, 2)], "7": [(4, 3)], "6": [(4, 4)],
    "p": [(5, 0)], "o": [(5, 1)], "i": [(5, 2)], "u": [(5, 3)], "y": [(5, 4)],
    "l": [(6, 1)], "k": [(6, 2)], "j": [(6, 3)], "h": [(6, 4)],
    "m": [(7, 2)], "n": [(7, 3)], "b": [(7, 4)],
})


def cpu_speed(remote):
    """Return ZEsarUX's numeric CPU-frequency readout without the ZRCP prompt."""
    response = remote.command("get-cpu-frequency")
    for line in response.splitlines():
        line = line.strip()
        if line and not line.startswith("command@"):
            return line
    return "unavailable"


def send_key_script(remote, script, press_instructions, settle_instructions,
                    report=None):
    """Send named keys/chords; `wN` waits N settle intervals."""
    idle = keyboard_matrix([])
    for step in (part.strip() for part in script.split(";")):
        if not step:
            continue
        if step.lower().startswith("w") and step[1:].isdigit():
            remote.run_cycles(max(1, int(step[1:])) * settle_instructions)
            if report is not None:
                report.append(f"CPU frequency after {step}: {cpu_speed(remote)}")
            continue
        chord, separator, hold = step.partition("~")
        keys = []
        for name in chord.lower().split("+"):
            if name not in KEYS:
                raise ValueError(f"unknown key in --keys script: {step}")
            keys.extend(KEYS[name])
        instructions = max(1, int(hold)) if separator else press_instructions
        remote.command("set-ui-io-ports " + keyboard_matrix(keys))
        remote.run_cycles(instructions)
        remote.command("set-ui-io-ports " + idle)
        remote.run_cycles(settle_instructions)
        if report is not None:
            report.append(f"CPU frequency after key {chord}: {cpu_speed(remote)}")


def run_to_tap_entry(remote, entry, instructions):
    """Submit the BASIC load command and stop at the TAP entry point."""
    remote.command("enable-breakpoints")
    breakpoint(remote, 1, entry)
    remote.command("set-ui-io-ports " + keyboard_matrix(KEYS["enter"]))
    remote.run_cycles(120_000)
    remote.command("set-ui-io-ports " + keyboard_matrix([]))
    pc, sp = registers(remote)
    if pc != entry:
        remote.run_cycles(instructions)
        pc, sp = registers(remote)
    if pc != entry:
        raise RuntimeError(f"did not reach TAP entry ${entry:04X}, stopped at ${pc:04X}")
    return sp


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tap", required=True, help="TAP file to load or insert")
    parser.add_argument("--zesarux", default=os.environ.get("ZESARUX", default_emulator()))
    parser.add_argument("--machine", default="BaseConf")
    parser.add_argument("--port", type=int, default=10040)
    parser.add_argument("--instructions", type=int, default=5_000_000,
                        help="opcodes to run after smartload and key injection")
    parser.add_argument("--boot-instructions", type=int, default=2_000_000,
                        help="opcodes to run before key injection")
    parser.add_argument("--key-instructions", type=int, default=50_000,
                        help="opcodes to hold each injected key")
    parser.add_argument("--key-settle-instructions", type=int, default=50_000,
                        help="opcodes to run after releasing each key")
    parser.add_argument("--keys", default="",
                        help="keys after loading, e.g. 'i;w40;load;quote;quote;enter;w40'")
    parser.add_argument("--tape-at-start", action="store_true",
                        help="insert TAP through ZEsarUX --tape when launching, without smartload")
    parser.add_argument("--noautoload", action="store_true",
                        help="preserve BaseConf when ZEsarUX smartloads a TAP")
    parser.add_argument("--shot", default="build/run-zesarux.png")
    parser.add_argument("--log", default="build/run-zesarux.log")
    parser.add_argument("--report", default="build/run-zesarux-report.txt")
    parser.add_argument("--stay", action="store_true", help="leave the emulator open")
    args = parser.parse_args()

    tap = os.path.abspath(args.tap)
    shot = os.path.abspath(args.shot)
    log_path = os.path.abspath(args.log)
    report_path = os.path.abspath(args.report)
    if not os.path.isfile(tap):
        parser.error(f"TAP does not exist: {tap}")
    for path in (shot, log_path, report_path):
        os.makedirs(os.path.dirname(path), exist_ok=True)

    extra_args = ["--hardware-debug-ports", "--realvideo"]
    if args.tape_at_start:
        extra_args.extend(("--tape", tap))
    if args.noautoload:
        extra_args.append("--noautoload")
    report = [f"machine={args.machine}", f"tap={tap}",
              f"noautoload={int(args.noautoload)}",
              f"tape_at_start={int(args.tape_at_start)}"]
    runner = ZesaruxRunner(
        args.zesarux,
        machine=args.machine,
        port=args.port,
        video_output="null",
        audio_output="null",
        extra_args=extra_args,
        log_path=log_path,
        quickexit=not args.stay,
    )

    try:
        runner.start()
        remote = runner.remote
        remote.enter_cpu_step()
        remote.run_cycles(args.boot_instructions)
        report.append("CPU frequency before loading: " + cpu_speed(remote))
        report.append("CPU turbo factor before loading: " + remote.command("get-cpu-turbo-speed").splitlines()[0].strip())
        report.append("before load: " + remote.command("get-registers").strip())
        if args.tape_at_start:
            report.append("load method: tape inserted with ZEsarUX --tape")
        else:
            smartload_response = remote.command(f'smartload "{tap.replace(chr(34), chr(92) + chr(34))}"')
            report.append("smartload response: " + smartload_response.strip())
        report.append("after load: " + remote.command("get-registers").strip())
        if args.keys:
            send_key_script(remote, args.keys,
                            args.key_instructions, args.key_settle_instructions,
                            report)
        remote.run_cycles(args.instructions)
        report.append("CPU frequency after loading: " + cpu_speed(remote))
        report.append("CPU turbo factor after loading: " + remote.command("get-cpu-turbo-speed").splitlines()[0].strip())
        report.append("final registers: " + remote.command("get-registers").strip())
        for address, length in ((0x4000, 16), (0x5800, 16), (0x7000, 16),
                                (0x7100, 16), (0x8000, 16), (0xC000, 16)):
            data = remote.read_memory(address, length)
            report.append(f"memory {address:04X} ({len(data)} bytes): {data.hex(' ')}")
        remote.save_screen(shot)
    except (OSError, ValueError, TimeoutError, RuntimeError) as exc:
        print(f"ZEsarUX TAP run failed: {exc}", file=sys.stderr)
        return 2
    finally:
        if args.stay and runner.process is not None:
            runner.detach()
        else:
            runner.close()

    with open(report_path, "w", encoding="utf-8") as output:
        output.write("\n".join(report) + "\n")
    print("\n".join(report))
    print(f"ZEsarUX log: {log_path}")
    print(f"screenshot: {shot}")
    print(f"debug report: {report_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
