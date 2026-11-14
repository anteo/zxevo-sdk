#!/usr/bin/env python3
"""Run the SDK library suites or an external assembly test suite."""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from tools.test_runner.suites.asm import AsmTestSuite
from tools.test_runner.suites.baseconf import BASECONF, BaseConfSuite
from tools.test_runner.suites.tsconf import TSCONF, TSConfSuite


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
        common.add_argument("--rom-symbols", type=Path, help="sjasmplus symbols for case ROM patches")
        common.add_argument("--sjasmplus", default="sjasmplus", help="sjasmplus executable")
        common.add_argument("--include-dir", type=Path, action="append", default=[],
                            help="add an assembly include directory (repeatable)")

    parser = argparse.ArgumentParser(prog=f"{Path(sys.argv[0]).name} {suite}")
    subparsers = parser.add_subparsers(dest="command")
    subparsers.add_parser("list", parents=[common], help="list discovered cases")
    subparsers.add_parser("build", parents=[common], help="prepare cases and manifests")
    subparsers.add_parser("check", parents=[common], help="run cases and compare results")
    subparsers.add_parser("clean", parents=[common], help="remove build outputs and local Python caches")
    if not argv or argv[0].startswith("-"):
        argv = ["check", *argv]
    return parser.parse_args(argv)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite", choices=("baseconf", "tsconf", "common", "asm"))
    parser.add_argument("suite_args", nargs=argparse.REMAINDER)
    entry = parser.parse_args()
    args = parse_suite_args(entry.suite, entry.suite_args)

    if entry.suite == "asm":
        suite = AsmTestSuite(args.suite_dir, args.build_dir, args.rom, args.rom_symbols,
                             sjasmplus=args.sjasmplus, include_dirs=args.include_dir)
        return suite.run(args)
    if entry.suite == "baseconf":
        return BaseConfSuite(BASECONF / "tests", "BaseConf").run(args)
    if entry.suite == "tsconf":
        return TSConfSuite(TSCONF / "tests", "TSConf").run(args)

    common = BASECONF.parent / "common/tests"
    suites = (
        BaseConfSuite(BASECONF / "tests", "BaseConf", common_tests=common),
        TSConfSuite(TSCONF / "tests", "TSConf", common_tests=common),
    )
    status = 0
    for suite in suites:
        print(suite.machine, flush=True)
        status = max(status, suite.run(args))
    return status


if __name__ == "__main__":
    sys.exit(main())
