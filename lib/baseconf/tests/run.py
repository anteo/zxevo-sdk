#!/usr/bin/env python3
"""Run the BaseConf library cases through the shared ZX Evolution test suite."""

import os
import sys
from pathlib import Path

TESTS = Path(__file__).resolve().parent
BASECONF = TESTS.parent
SUPPORT = TESTS / "support"
sys.path.insert(0, str(TESTS.parents[2]))

from tools.test_runner.runner import FrameworkError, TargetBuild, TestSuite, run_test_build  # noqa: E402


class BaseConfSuite(TestSuite):
    def build_target(self, profile, verbose):
        library = profile.get("library", {})
        build_dir = BASECONF / library.get("build_dir", "build/default")
        command = ["make", f"-j{os.cpu_count() or 1}", "-C", str(BASECONF),
                   f"BUILD={build_dir}", *library.get("make_args", []),
                   *library.get("make_targets", [])]
        if verbose:
            print("  " + " ".join(command))
        result = run_test_build(command, crash_log=build_dir / "library-build.sigsegv.log")
        if result.returncode != 0:
            tail = (result.stdout + result.stderr).strip().splitlines()[-12:]
            raise FrameworkError("library build failed:\n" + "\n".join(tail))

        config = BASECONF / "config" / "baseconf.cfg"
        common = BASECONF.parent / "common"
        common_include = common / "include"
        layout = profile["layout"]
        return TargetBuild(
            flags=[f"+{config}", f"-L{build_dir}", f"-Ca-I{SUPPORT}",
                   f"-I{BASECONF / 'include'}", f"-I{common_include}", f"-I{SUPPORT}",
                   f"-DBC_TEST_PINNED={int(layout['pinned'])}",
                   f"-DBC_TEST_SCRATCH={int(layout['scratch'])}"],
            env={"BASECONF_ROOT": str(BASECONF)},
            sources=(SUPPORT / "bc_case.c",),
            inputs=(Path(__file__), config, common / "config" / "basic48.cfg",
                    common / "crt" / "z80_crt0.asm", common / "crt" / "crt_stdio.inc",
                    common / "crt" / "crt_zx_lifecycle.inc", build_dir / "baseconf.lib",
                    SUPPORT / "bc_case.h", SUPPORT / "mmap.inc",
                    *sorted(common_include.rglob("*.h"))),
        )

    def page_write(self, window, page):
        return (0x3FF7 + window * 0x4000, 0x40 | ((~page) & 0x3F))

    def launch_ports(self, profile, layout):
        rom_bank = profile["layout"].get("rom_bank")
        ports = [(0xBF, 1)]
        if profile.get("mirror_resident_map"):
            if layout["code_window"] != 0 or rom_bank is not None or int(profile["layout"]["pinned"]) != 3:
                raise FrameworkError("mirror_resident_map requires W0 and W1 as the pinned RAM windows")
            # The loader fills the same physical pages through map 0.
            ports.extend([(0x7FFD, 0x10), self.page_write(0, layout["code_page"]),
                          self.page_write(1, layout["data_page"]), (0x7FFD, 0)])
        ports.append(self.page_write(1, layout["data_page"]))
        if rom_bank is not None:
            ports.append((0x3FF7, int(rom_bank)))
        return ports


if __name__ == "__main__":
    sys.exit(BaseConfSuite(TESTS, "BaseConf").run())
