#!/usr/bin/env python3
"""Run the shared library cases on BaseConf and TSConf."""

import sys
from pathlib import Path

TESTS = Path(__file__).resolve().parent
LIB = TESTS.parents[1]
sys.path.insert(0, str(LIB.parent))

from lib.baseconf.tests.run import BaseConfSuite  # noqa: E402
from lib.tsconf.tests.run import TSConfSuite  # noqa: E402


def main():
    suites = (
        BaseConfSuite(LIB / "baseconf" / "tests", "BaseConf", common_tests=TESTS),
        TSConfSuite(LIB / "tsconf" / "tests", "TSConf", common_tests=TESTS),
    )
    status = 0
    for suite in suites:
        print(suite.machine, flush=True)
        status = max(status, suite.run())
    return status


if __name__ == "__main__":
    sys.exit(main())
