# BaseConf tests

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

This directory contains the BaseConf test cases, their machine adapter and the older TAP probes. The
shared [ZX Evolution test harness](../../../tools/test_runner/README.en.md) drives the emulator and
compares results. [Common library cases](../../common/tests/README.en.md) run separately on both
machines. The console TAP tests are at the end. The font benchmark lives in
[`../bench/README.en.md`](../bench/README.en.md).

## Test framework

The framework runs library tests in ZEsarUX: it builds a C case, loads it through ZRCP/ZXHost,
executes steps and compares screen, text and data with expected files.

`cases/` contains package subdirectories with framework and functional cases. The runner discovers
`*.c` cases recursively. `list` shows paths relative to `cases/`, without the `.c` suffix. Expected
files sit beside their case and use the file stem.

### Quick start

```sh
make -C lib/baseconf/tests test            # build and check all cases
make -C lib/baseconf/tests shots           # write expected files (PASS only)
make -C lib/baseconf/tests framework-list  # list cases and expected files
python3 lib/baseconf/tests/run.py check --case core/helpers
python3 lib/baseconf/tests/run.py check --case core
```

Requirements: `zcc`, `z88dk-z80asm`, ZEsarUX with ZRCP, Python 3. Set `ZESARUX` for the executable
and `ZXEVO_TEST_ROM` for a specific ROM in the `ers-rom` profile. Otherwise the profile uses the
emulator's own ROM.

### Layout

```
lib/baseconf/tests/
  run.py                 BaseConf compiler and paging adapter
  profiles.json          BaseConf settings and composable build layers
  Makefile               console TAP and test runner targets
  cases/
    core/smoke.c                    framework self-check
    core/smoke.json                 optional case metadata
    core/smoke.01_zx256.png         expected file for step 1
    console/baseconf_printf.c       console package case
    graphics/graphics_primitives.c  graphics package case
  support/
    bc_case.h            BaseConf case initialization
    bc_case.c            BaseConf library initialization
    mmap.inc             DATA/BSS layout
  build/<package>/<case>/   build, manifest, map (ignored)
  out/<package>/            actual files, diff, report, log
    core/smoke.01_zx256.png
    core/smoke.report.json
    core/smoke.zesarux.log
```

### Runner pipeline

1. Finds `cases/**/*.c` and reads the matching `.json` file beside each case.
2. Builds the case for each profile with `zcc`:
   - classic + SDCC, `+config/baseconf.cfg`, `-SO3 -m`;
   - `CRT_ORG_CODE=0x0100`, `CRT_ORG_DATA=0x6800`, `CRT_ORG_BSS=0x7000`, `REGISTER_SP=0x7E00`;
   - case sources, `support/bc_case.c`, `lib/test_support/src/zx_test.c` and
     `lib/test_support/src/zx_host.c`;
   - `zx_host_config.h` is generated from `lib/test_support/protocol.json`.
3. Reads `.map` and validates addresses and sizes.
4. Writes `manifest.json` and the `code0`, `code1`, `DATA`, `vectors` images.
5. Starts ZEsarUX `--machine BaseConf` and loads the blocks:
   - `VECTORS` provides `RET` at `0008h–0030h` RST entries, `RETI` at `0038h` and `RETN` at `0066h`
     when code starts in W0;
   - `CODE0` in W0 (page 32), `CODE1`/`DATA` in W1 (page 33);
   - `OUT 0xBF,1` and W0/W1 mappings.
6. Runs the steps:
   - waits for `DONE` with the expected `sequence`;
   - reads `result0..3` and the log;
   - on the `DATA` flag, reads `DATA <addr> <len> <kind>` and the memory;
   - on the `SHOT` flag, advances 200,000 cycles and saves the screen;
   - on the `MORE` flag, sends the next request; otherwise ends the session.
7. Compares the outputs with the expected files next to the case and writes
   `out/<package>/<case>.report.json`.

### Memory map

| Window | Addresses   | Contents                       | Page    |
| ------ | ----------- | ------------------------------ | ------- |
| W0     | `0000–3FFF` | vectors and code/rodata        | RAM 32  |
| W1     | `4000–7FFF` | code, ZXHost, DATA, BSS, stack | RAM 33  |
| W2     | `8000–BFFF` | screen surface 0               | `page0` |
| W3     | `C000–FFFF` | screen surface 1               | `page1` |

| Region          | Address         | Limit                      |
| --------------- | --------------- | -------------------------- |
| code and rodata | `0100–5FFF`     | 24,320 bytes, end ≤ `6000` |
| ZXHost header   | `6000–601F`     | —                          |
| ZXHost log      | `6100–67FF`     | 1792 bytes                 |
| DATA            | `6800–6FFF`     | 2 KiB                      |
| BSS             | `7000–…`        | end + 1 KiB ≤ `7E00`       |
| stack           | `7E00` downward | —                          |

`run.py` checks these bounds from `.map` and stops the build on violation. Large initialized tables
go in `const` (rodata), or `data_org`/`bss_org` are raised in the profile.

In this layout W0 is mapped as RAM. Tests run with `BC_ERS_NONE`; interrupts are disabled and
vectors are replaced with stubs.

### Writing a test

A test is a normal C program with `main()`:

```c
#include <baseconf.h>
#include <zx/graphics.h>
#include "bc_case.h"

static const bc_surface_t surfaces[] = {
    {BC_VIDEO_ZX_256, 5, 5},
    /* ... */
};

int main(void) {
    if (bc_case_init() != ZX_OK) {
        zx_test_finish();
        return 0;
    }

    ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
    if (bc_set_video_mode(BC_VIDEO_ATM_640) == ZX_OK) {
        zx_set_ink(7);
        ZX_ASSERT(zx_console_clear() == ZX_OK);
        zx_draw_line(0, 0, 639, 199);
        zx_test_step_shot("atm640");
    } else {
        zx_test_step_skip("atm640", "mode unavailable");
    }

    zx_test_step_data(NULL, surfaces, sizeof(surfaces));
    zx_test_finish();
    return 0;
}
```

`zx_test_step_shot/data/binary/text/skip` complete the current step and wait for the host;
`zx_test_finish` ends the test. `name` is optional: `NULL` or an empty string uses the tag `out`.

| Function                                         | Purpose                                               |
| ------------------------------------------------ | ----------------------------------------------------- |
| `bc_case_init()`                                 | ZXHost, profile window mask, border 0, ink 7, paper 0 |
| `zx_test_step_shot(name)`                        | step with a screenshot                                |
| `zx_test_output_*()` + `zx_test_step_text(name)` | step with text                                        |
| `zx_test_step_data(name, ptr, len)`              | step with data as a hex dump                          |
| `zx_test_step_binary(name, ptr, len)`            | step with raw bytes                                   |
| `ZX_ASSERT(cond)`                                | check; a failure marks the step FAIL                  |
| `zx_test_step_skip(name, reason)`                | SKIP step                                             |
| `zx_test_finish()`                               | final verdict; the CPU stays in a loop                |

Video tests select screen 0 once for reproducible screenshots. Each call to `bc_set_video_mode()`
prepares the screen's draw surface in the available CPU windows.

### Result channels

| Channel   | API                                            | Expected file    |
| --------- | ---------------------------------------------- | ---------------- |
| screen    | `zx_test_step_shot(name)`                      | `.png`           |
| text      | `zx_test_output_*` + `zx_test_step_text(name)` | `.txt`           |
| data      | `zx_test_step_data(name, ptr, len)`            | `.txt`, hex dump |
| raw bytes | `zx_test_step_binary(name, ptr, len)`          | `.bin`           |
| logic     | `ZX_ASSERT(cond)`                              | no file          |

Non-graphics checks use one of three channels:

```c
/* table or structure */
static const bc_surface_t table[] = { /* ... */ };
zx_test_step_data(NULL, table, sizeof(table));

/* text */
zx_test_output_begin();
zx_test_output("paging=");
zx_test_output_hex8(bc_readback_register(0x0a));
zx_test_output(" border=");
zx_test_output_u16(0);
zx_test_output("\n");
zx_test_step_text(NULL);

/* large buffer */
zx_test_step_binary(NULL, buffer, sizeof(buffer));
```

A hex expected file looks like this:

```
0000: 00 05 05 01 05 05 02 04 05 03 01 05 04 01 05 05
0010: 01 05 06 08 08
```

The step log gets a `DATA <addr> <len> <kind>` line (`0` — hex, `1` — text, `2` — raw bytes). This
is a ZXHost log descriptor; after `DONE`, the host reads `len` bytes through ZRCP from `addr` while
the test waits for the next request, and compares them with the expected file. The buffer must be
mapped at that moment: BSS/data, stack, rodata or the current screen window. Length is `uint16_t`.
The text buffer is 512 bytes and truncates on overflow.

### Case metadata

`cases/<package>/<name>.json` (optional):

```json
{
  "description": "classic printf/gotoxy",
  "profiles": ["no-font8"],
  "timeout": 45,
  "defines": ["SOME_PARAMETER=1"],
  "sources": ["extra.c"]
}
```

- `profiles` — profile layers to merge for this case; omitted means use `default` only.
- `timeout` — seconds per step; default 30.
- `defines` — additional `-D` options.
- `sources` — additional files relative to the case source file.

### Profiles

`default` is always applied first and holds shared settings such as memory layout and the library
build directory. The names in a case's `profiles` array are then merged in order into one build
configuration. The CRT leaves stdio off by default. Cases that use standard streams or `printf()`
select the `stdio` layer.

| Layer           | Setting                               | Effect                                     |
| --------------- | ------------------------------------- | ------------------------------------------ |
| `stdio`         | `CRT_ENABLE_STDIO=1`                  | Enable CRT stdio and its console hook      |
| `no-stdio`      | `CRT_ENABLE_STDIO=0`                  | Disable CRT stdio and its console hook     |
| `no-font8`      | `BASECONF_CONSOLE_NO_DEFAULT_FONT=1`  | Omit the default 8×8 font from the library |
| `no-primitives` | `BASECONF_VIDEO_PRIMITIVE_MODES=NONE` | Omit graphics primitive backends           |

For example, `no-primitives` builds a text-only configuration. Conflicting assignments are reported
as an error.

Profile fields:

| Field                  | Purpose                                             |
| ---------------------- | --------------------------------------------------- |
| `layout`               | addresses, pages, windows; inherited from `default` |
| `library.build_dir`    | library build directory                             |
| `library.make_targets` | `make` targets                                      |
| `library.make_args`    | `make` arguments                                    |
| `library.extra_libs`   | additional `-l<name>` options                       |
| `cflags`               | additional `zcc` flags                              |
| `defines`              | additional `-D` options                             |

`newirq`: `src/newirq` objects are part of `baseconf.lib`; `<baseconf/newirq.h>` is always
available.

### Step protocol

ZXHost header — `0x6000` (32 bytes), log — `0x6100` (1792 bytes).

| Field     | Value                                          |
| --------- | ---------------------------------------------- |
| `result0` | `0` PASS, `1` FAIL, `2` SKIP                   |
| `result1` | step number                                    |
| `result2` | flags: `1` screenshot, `2` next step, `4` data |
| `result3` | 0                                              |

Step log:

```
<step name>
DATA <addr> <len> <kind>
FAIL line=<n> <expression>
```

`FAIL` is appended when `ZX_ASSERT` fails.

Sequence:

1. The host writes a request with `sequence=1` before starting the CPU.
2. The test runs a step, writes results, calls `zx_host_finish(DONE)` and waits.
3. The host sees `DONE` with its `sequence`, reads data and the screenshot, and sends `sequence+1`
   (`state=0`, sequence written last).
4. The test sees the new sequence, calls `zx_host_init()` and continues.

The screenshot is taken after `DONE`, when the test has stopped drawing.

### Expected files and names

Expected files live beside the case source and use its filename stem:

```
cases/<package>/<case>.<NN>_<tag>.<ext>
```

- `NN` — step number, starting at 1.
- `tag` is derived from the step name, lowercased, with runs of non-ASCII-alphanumeric characters
  replaced by hyphens and a 40-character limit. Missing or empty names use `out`.
- `ext` — `.png`, `.txt` or `.bin` for the channel.
- Actual files live in the matching `out/<package>/` directory with the same name.
- Build artifacts live in `build/<package>/<case>/`; report and log live in `out/<package>/`.
  Profile selection affects the build and run, not test or artifact names.

Example for `core/smoke.c`:

```
cases/core/smoke.01_zx256.png
cases/core/smoke.02_out.txt
cases/core/smoke.03_atm640.png
cases/core/smoke.04_out.txt
```

- `make ... shots` (`run.py check --update`) writes expected files on PASS.
- On PASS, `--update` removes expected files of this case/profile that no longer have a step.
- `make ... test` (`run.py check`) compares:
  - PNG: differing pixel count, first difference coordinate, `out/<package>/<name>.diff.png`;
  - text: unified diff in `out/<package>/<stem>.diff.txt`;
  - binary: first differing offset and a hex window.
- An expected file without a produced output is an error; remove the file manually or through
  `--update` on PASS.

### CLI

```sh
python3 lib/baseconf/tests/run.py list [--case PATH]
python3 lib/baseconf/tests/run.py build [--case PATH] [--profile NAME]
python3 lib/baseconf/tests/run.py check [--case PATH] [--filter REGEX]
                                       [--update] [--no-build] [--fail-fast]
                                       [--timeout SEC] [--port N] [--zesarux PATH] [--verbose]
python3 lib/baseconf/tests/run.py clean [--case PATH]
```

- `check` is the default command.
- `--update` writes expected files next to the case and removes stale ones (PASS only).
- `--no-build` reuses the last `build/<package>/<case>/manifest.json` for that case.
- `--fail-fast` stops after the first case that reports a result mismatch.
- `--case` takes a path relative to `cases/`. Use `core/helpers` for one case or `core` for all
  cases under that directory. A unique file stem such as `helpers` also works. Repeat `--case` to
  combine selections.
- `--profile` is repeatable and selects cases that use any named layer. Each selected case keeps its
  complete profile.
- `clean` removes generated files in `build/` and `out/` and local Python caches. With `--case`, it
  removes only the selected cases' generated files.

Exit codes: `0` — PASS, `1` — FAIL or build error, `2` — emulator/ZRCP error.

### Determinism

- machine `BaseConf`, `--realvideo`, `--vo null`;
- 2,000,000 boot cycles, with keyboard input opt-in per test;
- `DI`, border 0; scenes without FLASH/ULAPlus/RTC/PS2/UART;
- screenshot 200,000 cycles after `DONE`;
- full-frame comparison unless case metadata specifies a region;
- emulator log in `out/<package>/<case>.zesarux.log`.

### Limitations

- The default layout maps RAM in W0. The `ers-rom` profile keeps ROM in W0.
- The harness starts with maskable interrupts disabled. Interrupt cases install their own handlers.
- Code and rodata up to 24,320 bytes; large scenes are split into cases.
- One emulator per run; parallel runs on the same port are not supported.
- Flash programming, paged AVR EEPROM and `newirq` sources require hardware support beyond this
  emulator. The RTC clock case checks BCD and the PS/2 case checks make and break codes.

Cases can pass extra ZEsarUX command-line options as an `emulator_args` array in their JSON
metadata. Interactive cases can use `emulator_steps`. Each key names a target marker. After resuming
that marker, the runner can generate `nmi`, run `settle` instructions, send `before_shot_keys`,
capture a `shot`, then send `keys`. Key scripts accept names and chords such as `f;break;0`. An
optional `region` of `[x, y, width, height]` limits comparison to stable pixels such as a menu,
while the saved screenshot retains the full frame. An action with `uart.send` or `uart.expect`
exchanges byte arrays over a raw POSIX pseudoterminal while the target waits at that marker. The
UART case requires a ZEsarUX build with BaseConf UART support and the `--uartbridge-file` option.

### Coverage

Run `make -C lib/baseconf/tests framework-list` for the current case list. Select a group with
`--case` and its directory name.

| Group                                 | Examples                                                                       |
| ------------------------------------- | ------------------------------------------------------------------------------ |
| `core`, `memory`                      | Lifecycle, paging, window leases, readback, Flash and the banked heap          |
| `video`, `palette`, `graphics`        | Video modes, ATM and ULAplus palettes, drawing, clipping and scrolling         |
| `console`, `font`                     | `zx_console_printf`, CRT stdio, fonts and text in graphics modes               |
| `input`, `rtc`, `timing`, `interrupt` | PS/2, RTC, CPU speed, interrupt and NMI behavior                               |
| `storage`, `ers`                      | Direct SD and FDD interfaces, ERS storage, FAT, mounter and other ROM services |

Shared cases for audio, Kempston mouse, UART, Nemo IDE, ZX attributes, SD card data, AVR version
records and the RAM pool/heap are maintained under `lib/common/tests`.
[Common suite](../../common/tests/README.en.md)

## Console TAP tests

`make -C lib/baseconf/tests run TEST_MODE=0 TEST_FONT=5 TEST_SCROLL=1` builds and runs the ZX256
`zx_console_printf` TAP test in ZEsarUX. `make -C lib/baseconf/tests run-crt TEST_MODE=0` checks
ordinary CRT `printf` through the generic console. The TAP reports and screenshots are written under
`tests/build/`.
