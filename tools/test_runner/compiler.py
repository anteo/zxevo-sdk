"""Build with z88dk and read the linker map."""

import hashlib
import os
import re
import signal
import subprocess
from dataclasses import dataclass
from pathlib import Path

from .support import TEST_SUPPORT, FrameworkError


ZCC = os.environ.get("ZCC", "zcc")
TEST_SUPPORT_C = TEST_SUPPORT / "c"
ZX_HOST_SOURCE = TEST_SUPPORT_C / "zx_host.c"
ZXTEST_SOURCE = TEST_SUPPORT_C / "zx_test.c"


# zcc converts its compiler child's exit status to 1. The shell still
# identifies the crashed executable in stderr, including under make.
SDCC_SIGSEGV = re.compile(
    r"^(?:[^:\n]+: )?(?:line \d+: )?(?:\d+\s+)?Segmentation fault"
    r"(?:: 11| \(core dumped\))?\s+[^\n]*\bz88dk-zsdcc\b",
    re.MULTILINE,
)


def run_test_build(command, *, crash_log, env=None):
    """Retry one compiler crash and preserve the first attempt's diagnostics."""
    result = subprocess.run(command, capture_output=True, text=True, env=env)
    if not result.returncode or not (
            result.returncode == -signal.SIGSEGV or SDCC_SIGSEGV.search(result.stderr)):
        return result

    crash_log.parent.mkdir(parents=True, exist_ok=True)
    crash_log.write_text(result.stdout + result.stderr, encoding="utf-8")
    print(f"\n  RETRY 2/2: compiler SIGSEGV, see {crash_log}", flush=True)
    return subprocess.run(command, capture_output=True, text=True, env=env)


@dataclass(frozen=True)
class TargetBuild:
    """Configuration-specific arguments, environment, sources and cache inputs."""

    flags: list[str]
    env: dict[str, str]
    sources: tuple[Path, ...]
    inputs: tuple[Path, ...]


def file_digest(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(65536), b""):
            digest.update(block)
    return digest.hexdigest()


def parse_map(path):
    symbols = {}
    pattern = re.compile(r"^(\S+)\s+= \$([0-9A-Fa-f]+)")
    with open(path, "r", encoding="utf-8", errors="replace") as stream:
        for line in stream:
            match = pattern.match(line)
            if match:
                symbols[match.group(1)] = int(match.group(2), 16)
    return symbols


def map_symbol(symbols, name):
    if name not in symbols:
        raise FrameworkError(f"map has no {name} symbol")
    return symbols[name]


def generate_vectors(path):
    data = bytearray(256)
    for address in (0x08, 0x10, 0x18, 0x20, 0x28, 0x30):
        data[address] = 0xC9  # RET
    data[0x38] = 0xED  # RETI
    data[0x39] = 0x4D
    data[0x66] = 0xED  # RETN
    data[0x67] = 0x45
    with open(path, "wb") as stream:
        stream.write(data)
