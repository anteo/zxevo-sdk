"""Verify a banked TAP through the BASIC 48 loader on ZX Evolution."""

import argparse
import os
import socket
from pathlib import Path

from tools.test_runner.runner import console_label, map_symbol, parse_map
from tools.zesarux.runner import ZesaruxRunner, breakpoint, default_emulator, registers, return_site
from tools.zesarux.tap_runner import run_to_tap_entry, send_key_script


BANKS = (0x1B, 0xA5)
INITIAL_TSCONF_PAGE = 0x11


def start_basic(remote, machine):
    if machine == "BaseConf":
        remote.run_cycles(2_000_000)
        send_key_script(remote, "i;w8", 120_000, 100_000)
        return

    # TSConf's BASIC 48 ROM is in page 3. Start it with a nonzero page in W3
    # to distinguish restoration from simply setting Page3 to zero.
    for address, value in ((0x00AF, 0x20), (0x10AF, 3), (0x11AF, 5), (0x12AF, 2),
                           (0x13AF, INITIAL_TSCONF_PAGE), (0x15AF, 0), (0x20AF, 0),
                           (0x21AF, 4), (0x2AAF, 1)):
        remote.write_port(address, value)
    remote.set_register("PC=0")
    remote.run_cycles(2_000_000)


def verify_banks(remote, tape, symbols):
    # ZEsarUX zone 0 exposes the physical RAM on both machines.
    remote.command("set-memory-zone 0")
    try:
        for page in BANKS:
            bank = f"{page:02X}"
            expected = tape.with_name(f"{tape.stem}_BANK_{bank}.bin").read_bytes()
            address = map_symbol(symbols, f"__BANK_{bank}_head") & 0xFFFF
            physical = page * 0x4000 + (address & 0x3FFF)
            actual = remote.read_memory(physical, len(expected))
            if actual != expected:
                raise RuntimeError(f"Bank {bank} at {address:04X}h: "
                                   f"expected {expected.hex()}, got {actual.hex()}")
    finally:
        remote.command("set-memory-zone -1")


def verify_tape(tape, machine, emulator, rom):
    symbols = parse_map(tape.with_suffix(".map"))
    entry = map_symbol(symbols, "start")
    extra_args = ["--hardware-debug-ports", "--noautoload", "--tape", str(tape)]
    if rom:
        extra_args.extend(("--romfile", str(rom)))
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]

    log = tape.with_suffix(".zesarux.log")
    with ZesaruxRunner(emulator, machine=machine, port=port, extra_args=extra_args,
                       log_path=log) as runner:
        remote = runner.remote
        remote.enter_cpu_step()
        start_basic(remote, machine)
        send_key_script(remote, "load;quote;quote", 50_000, 50_000)
        sp = run_to_tap_entry(remote, entry, 2_000_000)
        expected_page = INITIAL_TSCONF_PAGE if machine == "TSConf" else BANKS[-1]
        pages = remote.command("get-memory-pages").splitlines()[0].split()
        if len(pages) != 4 or pages[3] != f"A{expected_page}":
            raise RuntimeError(f"Expected W3 to map RAM {expected_page:02X}h at entry, got {pages}")
        verify_banks(remote, tape, symbols)

        basic_pc, basic_sp = return_site(remote, sp)
        breakpoint(remote, 1, basic_pc, basic_sp)
        remote.run_cycles(100_000)
        if registers(remote) != (basic_pc, basic_sp):
            raise RuntimeError("The program did not return to BASIC")
        if " BC=0000 " not in remote.command("get-registers").splitlines()[0]:
            raise RuntimeError("The program returned a nonzero status to BASIC")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("machine", choices=("BaseConf", "TSConf"))
    parser.add_argument("tape", type=Path)
    parser.add_argument("--zesarux", default=default_emulator())
    parser.add_argument("--rom", type=Path, default=os.environ.get("ZXEVO_TEST_ROM"))
    args = parser.parse_args()
    tape = args.tape.resolve()
    try:
        verify_tape(tape, args.machine, args.zesarux, args.rom.resolve() if args.rom else None)
    except (OSError, ValueError, RuntimeError) as exc:
        log = tape.with_suffix(".test.log")
        log.write_text(f"{exc}\nZEsarUX log: {tape.with_suffix('.zesarux.log')}\n", encoding="utf-8")
        print(f"{console_label('FAIL')}  {args.machine} banked TAP (see {log})")
        raise SystemExit(1)
    print(f"{console_label('PASS')}  {args.machine} banked TAP")


if __name__ == "__main__":
    main()
