"""Shared paths, diagnostics and console formatting for SDK tests."""

import os
import sys
from pathlib import Path


TEST_RUNNER = Path(__file__).resolve().parent
ROOT = TEST_RUNNER.parents[1]
TEST_SUPPORT = ROOT / "lib" / "test_support"
PROTOCOL_FILE = TEST_SUPPORT / "protocol.json"
PAGE_SIZE = 0x4000


LABEL_COLORS = {
    "BUILD": "1;36",
    "BUILD FAIL": "1;31",
    "RUN": "1;35",
    "PASS": "1;32",
    "FAIL": "1;31",
    "SKIP": "1;33",
    "error": "1;31",
}


def interactive_console(stream):
    return stream.isatty() and os.environ.get("TERM") != "dumb"


def console_label(label, width=0, *, stream=None):
    if stream is None:
        stream = sys.stdout
    padded_label = label.ljust(width)
    color = LABEL_COLORS.get(label)
    if color and interactive_console(stream) and not os.environ.get("NO_COLOR"):
        return f"\033[{color}m{padded_label}\033[0m"
    return padded_label


def step_prefix(number):
    return f"  STEP {number}: "


class FrameworkError(RuntimeError):
    """A build or infrastructure failure, not a test failure."""


class TestFailure(RuntimeError):
    """A test failed in the target or in the golden comparison."""
