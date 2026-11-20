#!/usr/bin/env python3
"""Run the SDK library suites or an external assembly test suite."""

import argparse
import sqlite3
import sys
import tomllib
from contextlib import closing
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.test_runner.discovery import discover_suites
from tools.test_runner.emulator import find_zesarux
from tools.test_runner.history import (
    HISTORY_PATH, count_pending, load_failures, load_pending, open_history, record_outcome, start_plan,
)
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
    check = subparsers.add_parser("check", parents=[common], help="run cases and compare results")
    if suite != "asm":
        selection = check.add_mutually_exclusive_group()
        selection.add_argument("--rerun-failed", action="store_true",
                               help="run only previously failed cases in their recorded profiles")
        selection.add_argument("--continue", dest="resume", action="store_true",
                               help="run the remaining cases from an interrupted or stopped plan")
    if suite != "all":
        subparsers.add_parser("build", parents=[common], help="prepare cases and manifests")
        subparsers.add_parser("clean", parents=[common], help="remove build outputs and local Python caches")
    if not argv or argv[0].startswith("-"):
        argv = ["check", *argv]
    return parser.parse_args(argv)


def select_recorded_runs(name, suite, runs, recorded):
    selected = []
    for case_path, meta, profiles in runs:
        case = suite.case_relative_path(case_path).as_posix()
        profiles = [profile for profile in profiles
                    if (name, suite.machine, case, profile["name"]) in recorded]
        if profiles:
            selected.append((case_path, meta, profiles))
    return selected


def planned_run_keys(plan):
    for name, suite, runs in plan:
        for case_path, _, profiles in runs:
            case = suite.case_relative_path(case_path).as_posix()
            for profile in profiles:
                yield (name, suite.machine, case, profile["name"])


def run_combined(args, selected, scope):
    """Plan every matching case before running any machine."""
    rerun_failed = args.command == "check" and args.rerun_failed
    resume = args.command == "check" and args.resume
    if resume and (args.case or args.profile or args.filter):
        raise FrameworkError("--continue uses the saved plan; omit --case, --profile and --filter")
    recorded = None
    plan_id = None
    if rerun_failed:
        recorded = load_failures()
    elif resume:
        plan_id, recorded = load_pending(scope)
    missing = set(args.case or ())
    plan = []
    for name, suite in selected:
        unmatched = set()
        runs = suite.enumerate_runs(args, suite.load_profiles(), unmatched=unmatched)
        missing.intersection_update(unmatched)
        if recorded is not None:
            runs = select_recorded_runs(name, suite, runs, recorded)
        if runs:
            plan.append((name, suite, runs))
    if missing:
        selector = next(case for case in args.case if case in missing)
        raise FrameworkError(f"unknown case or directory {selector!r}; use 'list' to see cases")

    if args.command == "list":
        if not plan:
            print("no cases")
        for name, suite, runs in plan:
            print(f"{name}/{suite.machine}", flush=True)
            suite.list_runs(runs)
        return 0

    summary = CheckSummary()
    if not plan:
        if rerun_failed:
            print("No recorded failures match the selection.")
        if resume:
            print("No remaining tests in the saved plan.")
    else:
        zesarux = find_zesarux(args.zesarux)
        try:
            with closing(open_history()) as history:
                if not resume and not rerun_failed:
                    plan_id = start_plan(history, scope, planned_run_keys(plan))
                for name, suite, runs in plan:
                    label = f"{name}/{suite.machine}"
                    print(label, flush=True)

                    def record(key, failed):
                        record_outcome(history, (name, suite.machine, *key), failed,
                                       scope=scope, plan_id=plan_id)

                    try:
                        suite.check_runs(args, runs, zesarux, summary, label_prefix=f"{label}/",
                                         record_outcome=record)
                    except (FrameworkError, OSError, tomllib.TOMLDecodeError) as error:
                        summary.suite_errors += 1
                        summary.failed_runs.append(f"{label} (suite error)")
                        print(f"{console_label('error', stream=sys.stderr)}: {label}: {error}",
                              file=sys.stderr)
                    if args.fail_fast and summary.exit_code:
                        break
        except sqlite3.Error as error:
            summary.suite_errors += 1
            print(f"{console_label('error', stream=sys.stderr)}: {HISTORY_PATH}: {error}",
                  file=sys.stderr)
    try:
        summary.pending = count_pending(scope)
    except sqlite3.Error as error:
        summary.suite_errors += 1
        print(f"{console_label('error', stream=sys.stderr)}: {HISTORY_PATH}: {error}", file=sys.stderr)
    summary.print_report(args.update)
    return summary.exit_code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite", help="SDK suite name, all, or asm")
    parser.add_argument("suite_args", nargs=argparse.REMAINDER)
    entry = parser.parse_args()

    try:
        return run_suite(parser, entry)
    except (FrameworkError, OSError, sqlite3.Error, tomllib.TOMLDecodeError) as error:
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
        return run_combined(args, [(name, suite) for name in names for suite in suites[name]], "all")

    targets = suites[entry.suite]
    if args.command == "check" or (args.command == "list" and len(targets) > 1):
        return run_combined(args, [(entry.suite, suite) for suite in targets], entry.suite)
    if len(targets) == 1:
        return targets[0].run(args)

    status = 0
    for suite in targets:
        print(suite.machine, flush=True)
        status = max(status, suite.run(args))
    return status


if __name__ == "__main__":
    sys.exit(main())
