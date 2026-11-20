#!/usr/bin/env python3
"""Run the SDK library suites or an external assembly test suite."""

import argparse
import sys
import tomllib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.test_runner.discovery import discover_suites
from tools.test_runner.emulator import find_zesarux
from tools.test_runner.suites.asm import AsmTestSuite
from tools.test_runner.suites.base import CheckSummary
from tools.test_runner.support import FrameworkError, console_label


def parse_suite_args(suite, argv):
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--case", action="append", metavar="PATH",
                        help="case or directory under cases/ (repeatable)")
    common.add_argument("--profile", action="append", help="select a full profile name (repeatable)")
    common.add_argument("--filter", help="regular expression on case names")
    common.add_argument("--update", action="store_true", help="write actual results as expected")
    common.add_argument("--no-build", action="store_true", help="reuse the last launch manifest")
    common.add_argument("--fail-fast", action="store_true", help="stop after the first failing case")
    common.add_argument("--timeout", type=float, help="seconds per test step")
    common.add_argument("--port", type=int, default=10040, help="ZRCP port")
    common.add_argument("--zesarux", help="ZEsarUX executable")
    common.add_argument("--verbose", action="store_true")
    if suite == "asm":
        common.add_argument("--suite-dir", type=Path, required=True, help="directory with profiles.toml and cases/")
        common.add_argument("--build-dir", type=Path, required=True, help="directory for ASM build and test outputs")
        common.add_argument("--rom", type=Path, required=True, help="ROM image to load")
        common.add_argument("--rom-symbols", type=Path, help="sjasmplus symbols for boot checkpoints and case ROM patches")
        common.add_argument("--sjasmplus", default="sjasmplus", help="sjasmplus executable")
        common.add_argument("--include-dir", type=Path, action="append", default=[],
                            help="add an assembly include directory (repeatable)")

    parser = argparse.ArgumentParser(prog=f"{Path(sys.argv[0]).name} {suite}")
    subparsers = parser.add_subparsers(dest="command")
    subparsers.add_parser("list", parents=[common], help="list discovered cases")
    subparsers.add_parser("check", parents=[common], help="run cases and compare results")
    if suite != "all":
        subparsers.add_parser("build", parents=[common], help="prepare cases and manifests")
        subparsers.add_parser("clean", parents=[common], help="remove build outputs and local Python caches")
    if not argv or argv[0].startswith("-"):
        argv = ["check", *argv]
    return parser.parse_args(argv)


def run_combined(args, selected):
    """Plan every matching case before running any machine."""
    missing = set(args.case or ())
    plan = []
    for name, suite in selected:
        unmatched = set()
        runs = suite.enumerate_runs(args, suite.load_profiles(), unmatched=unmatched)
        missing.intersection_update(unmatched)
        if runs:
            plan.append((f"{name}/{suite.machine}", suite, runs))
    if missing:
        selector = next(case for case in args.case if case in missing)
        raise FrameworkError(f"unknown case or directory {selector!r}; use 'list' to see cases")

    if args.command == "list":
        if not plan:
            print("no cases")
        for label, suite, runs in plan:
            print(label, flush=True)
            suite.list_runs(runs)
        return 0

    summary = CheckSummary()
    if plan:
        zesarux = find_zesarux(args.zesarux)
        for label, suite, runs in plan:
            print(label, flush=True)
            try:
                suite.check_runs(args, runs, zesarux, summary, label_prefix=f"{label}/")
            except (FrameworkError, OSError, tomllib.TOMLDecodeError) as error:
                summary.suite_errors += 1
                summary.failed_runs.append(f"{label} (suite error)")
                print(f"{console_label('error', stream=sys.stderr)}: {label}: {error}", file=sys.stderr)
            if args.fail_fast and summary.exit_code:
                break
    summary.print_report(args.update)
    return summary.exit_code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite", help="SDK suite name, all, or asm")
    parser.add_argument("suite_args", nargs=argparse.REMAINDER)
    entry = parser.parse_args()

    try:
        return run_suite(parser, entry)
    except (FrameworkError, OSError, tomllib.TOMLDecodeError) as error:
        print(f"{console_label('error', stream=sys.stderr)}: {error}", file=sys.stderr)
        return 2


def run_suite(parser, entry):
    if entry.suite == "asm":
        args = parse_suite_args("asm", entry.suite_args)
        suite = AsmTestSuite(args.suite_dir, args.build_dir, args.rom, args.rom_symbols,
                             sjasmplus=args.sjasmplus, include_dirs=args.include_dir)
        return suite.run(args)

    suites = discover_suites()
    if entry.suite != "all" and entry.suite not in suites:
        choices = ", ".join(("all", *suites, "asm"))
        parser.error(f"unknown suite {entry.suite!r}; choose from {choices}")
    if entry.suite == "all" and not suites:
        raise FrameworkError("no SDK test suite manifests found")
    args = parse_suite_args(entry.suite, entry.suite_args)
    if entry.suite == "all":
        names = sorted(suites, key=lambda name: (len(suites[name]) > 1, name))
        return run_combined(args, [(name, suite) for name in names for suite in suites[name]])

    targets = suites[entry.suite]
    if len(targets) == 1:
        return targets[0].run(args)
    if args.command in {"check", "list"}:
        return run_combined(args, [(entry.suite, suite) for suite in targets])

    status = 0
    for suite in targets:
        print(suite.machine, flush=True)
        status = max(status, suite.run(args))
    return status


if __name__ == "__main__":
    sys.exit(main())
