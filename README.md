# zxevo-sdk

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

C and Z80 assembly libraries for ZX Evolution applications targeting BaseConf or TSConf. The SDK
includes z88dk target configurations, a BASIC 48 startup profile, emulator tests and host tools.

- **BaseConf** supports paging, video, console output, peripherals, direct storage access and ERS
  ROM services. Start with `<baseconf.h>`. [Documentation](lib/baseconf/README.en.md)
- **TSConf** supports paging, video, console output, tiles, sprites, DMA, peripherals, direct SD
  access and TS-BIOS FAT services. Start with `<tsconf.h>`. [Documentation](lib/tsconf/README.en.md)
- **Common APIs** in the `zx/` headers cover graphics, fonts, formatted output, banked memory, audio
  and peripherals. Both archives include the shared code. [Documentation](lib/common/README.en.md)

## Build the libraries

Use GNU Make and z88dk with its SDCC compiler and classic library. Put `zcc` and `z88dk-z80asm` on
`PATH` and point `ZCCCFG` at the standard z88dk configurations. `ZCC` and `Z80ASM` override the
executable names used by the build.

```sh
export PATH="/path/to/z88dk/bin:$PATH"
export ZCCCFG=/path/to/z88dk/lib/config
make
```

| Target              | Default output                                                               |
| ------------------- | ---------------------------------------------------------------------------- |
| `make baseconf-lib` | `lib/baseconf/build/default/baseconf.lib`                                    |
| `make tsconf-lib`   | `lib/tsconf/build/default/tsconf.lib` and `tsconf.cfg` in the same directory |

`make` builds both archives. BaseConf can select text and graphics backends separately. TSConf uses
`TSCONF_VIDEO_MODES` to select the console and drawing backends. For a ZX-only TSConf build, use
`make tsconf-lib TSCONF_VIDEO_MODES=ZX`. See the library documentation for the other build options.
[BaseConf options](lib/baseconf/README.en.md#application-size) ·
[TSConf options](lib/tsconf/README.en.md#selecting-video-backends)

## Use the SDK in an application

Set `ZXEVO_SDK_PATH` to the absolute path of this checkout and include the Make fragment for your
target. The fragment supplies include paths, the archive location and the classic SDCC ABI flags
(`-clib=classic -compiler=sdcc --reserve-regs-iy`). The target configuration already selects the
matching archive.

| Target   | Make fragment under `ZXEVO_SDK_PATH` | Application flags       | BASIC 48 TAP flags          |
| -------- | ------------------------------------ | ----------------------- | --------------------------- |
| BaseConf | `lib/baseconf/baseconf.mk`           | `$(BASECONF_APP_FLAGS)` | `$(BASECONF_BASIC48_FLAGS)` |
| TSConf   | `lib/tsconf/tsconf.mk`               | `$(TSCONF_APP_FLAGS)`   | `$(TSCONF_BASIC48_FLAGS)`   |

First build `tsconf.lib` with `make -C /absolute/path/to/zxevo-sdk tsconf-lib`. This application
Makefile then builds `demo.tap` from `main.c`. Run it with
`make ZXEVO_SDK_PATH=/absolute/path/to/zxevo-sdk`.

```makefile
.DEFAULT_GOAL := demo.tap
include $(ZXEVO_SDK_PATH)/lib/tsconf/tsconf.mk

demo.tap: main.c $(TSCONF_LIB)
	$(ZCC) $(TSCONF_BASIC48_FLAGS) -m -create-app -o demo main.c
```

For a BaseConf BASIC 48 TAP, use the BaseConf fragment, `$(BASECONF_LIB)` and
`$(BASECONF_BASIC48_FLAGS)`. Build `baseconf-appmake` first with
`make -C lib/baseconf baseconf-appmake Z88DK_SRC=/path/to/z88dk/src` from the SDK checkout. The
helper also requires a host C compiler, `patch` and GMP development files. TSConf's BASIC 48 profile
uses the standard z88dk appmake. [BaseConf appmake](tools/appmake/README.en.md)

The BASIC 48 profile disables CRT stdio. For formatted output, use `zx_console_printf()` from
`<zx/printf.h>` after configuring the target console. [Common APIs](lib/common/README.en.md)

`make examples` builds the BaseConf and TSConf examples as individual BASIC 48 TAPs. Use
`make examples-baseconf` or `make examples-tsconf` to build for one machine. The sources live in
each library's `examples/` directory and the TAPs go to its `build/examples/` directory.
[BaseConf examples](lib/baseconf/README.en.md#tests-and-examples) ·
[TSConf examples](lib/tsconf/README.en.md#basic-48-startup-profile) ·
[Loading the TAPs](lib/common/README.en.md#basic-48-startup-profile)

## Run tests

The test runner needs Python 3 and ZEsarUX with ZRCP and the hardware features exercised by each
case. `make test` runs the BaseConf, TSConf and common suites. Use `make test-baseconf`,
`make test-tsconf` or `make test-common` to select a suite. The common suite runs on both machines.

```sh
make test ZESARUX=/path/to/zesarux ZXEVO_TEST_ROM=/path/to/ZXEVO.ROM
python3 lib/tsconf/tests/run.py check --case video/video
```

`ZESARUX` selects the emulator executable. Otherwise the runner looks on `PATH` and in standard
installation locations. `ZXEVO_TEST_ROM` overrides the emulator ROM only for the `ers-rom` and
`ts-bios` profiles. Choose a ROM that matches the selected machine and profile. Some cases require
specific emulator support, such as a host serial bridge. Cases for some optional devices use
fixtures to test the driver protocol. [Test harness](lib/test_support/README.en.md) ·
[BaseConf tests](lib/baseconf/tests/README.en.md) ·
[TSConf tests](lib/tsconf/README.en.md#emulator-tests) ·
[Common tests](lib/common/tests/README.en.md)

The suites keep binaries and manifests under `tests/build/` and reports and captures under
`tests/out/` in their respective library directories. The common suite adds a `baseconf/` or
`tsconf/` subdirectory. `make clean` removes the SDK's build and test outputs and Python caches.

## Host tools

- `python3 tools/profiling/memory.py path/to/program.map --sort size` reports memory areas,
  modules and function ranges from a z88dk map generated with `-m`.
- `python3 -m tools.profiling.cpu` measures a TAP function and selected calls in an isolated
  ZEsarUX process. It reads the sibling `.map` by default. Selected calls include their callees, and
  nested selected calls are counted only in the outer call. Use `--output` for per-call JSON.
  Profile caller-clean routines in resident code. Use `--keys` for a different BASIC startup
  sequence, leaving out the final Enter, and `--zesarux` or `--rom` to select the emulator or ROM.
- ZXHost provides a target-side mailbox and Python tools for loading and controlling a program
  through ZRCP. [ZXHost](lib/test_support/README.en.md#zxhost-target-runtime-and-mailbox)
- `make format` formats C, ASM and Markdown. [Formatter](tools/formatter/README.en.md)

To measure Night Train's drawing routine after `make examples-baseconf`, run from the SDK root.

```sh
python3 -m tools.profiling.cpu \
  --tap lib/baseconf/build/examples/night_train.tap --entry draw_station \
  --functions zx_draw_fill_rect zx_console_draw_op zx_console_clear
```
