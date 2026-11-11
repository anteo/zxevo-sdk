#!/usr/bin/env python3
"""Run the TSConf library cases on the ZEsarUX TSConf machine."""

import sys
from pathlib import Path

TESTS = Path(__file__).resolve().parent
TSCONF = TESTS.parent
sys.path.insert(0, str(TESTS.parents[2]))

from lib.test_support.runner import (  # noqa: E402
    TEST_SUPPORT_INCLUDE, FrameworkError, TargetBuild, TestSuite, run_test_build,
)


class TSConfSuite(TestSuite):
    def build_target(self, profile, verbose):
        library = profile.get("library", {})
        build_dir = TSCONF / library.get("build_dir", "build/tests")
        command = ["make", "-C", str(TSCONF), f"BUILD={build_dir}",
                   *library.get("make_args", []), "all"]
        if verbose:
            print("  " + " ".join(command))
        result = run_test_build(command, crash_log=build_dir / "library-build.sigsegv.log")
        if result.returncode != 0:
            raise FrameworkError("library build failed:\n" + (result.stdout + result.stderr).strip())

        include = TSCONF / "include"
        config = build_dir / "tsconf.cfg"
        common = TSCONF.parent / "common"
        common_include = common / "include"
        data_page = profile["layout"]["data_page"]
        flags = [f"+{config}", f"-L{build_dir}", f"-I{include}", f"-I{common_include}",
                 f"-Ca-I{TEST_SUPPORT_INCLUDE}",
                 f"-DTS_TEST_DATA_PAGE={data_page}"]
        return TargetBuild(
            flags=flags,
            env={},
            sources=(),
            inputs=(Path(__file__), config, common / "config" / "basic48.cfg",
                    common / "crt" / "z80_crt0.asm", common / "crt" / "crt_stdio.inc",
                    common / "crt" / "crt_zx_lifecycle.inc",
                    build_dir / "tsconf.lib", TEST_SUPPORT_INCLUDE / "mmap.inc",
                    *sorted(common_include.rglob("*.h")),
                    *sorted(include.rglob("*.h"))),
        )

    def page_write(self, window, page):
        return (0x10AF + (window << 8), page)

    def launch_ports(self, profile, layout):
        # The loader takes over after ROM startup. Clear FMAPS and interrupts,
        # turn off CPU caching and map the ROM selected for W0.
        return [(0x15AF, 0), (0x2AAF, 0), (0x20AF, 0), (0x21AF, 4),
                self.page_write(0, profile["layout"].get("rom_bank", 3)),
                self.page_write(1, layout["data_page"])]


if __name__ == "__main__":
    sys.exit(TSConfSuite(TESTS, "TSConf").run())
