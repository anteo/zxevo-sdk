# ZX Evolution test support

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

`runner.py` is the entry point for the C and ASM suites. `suites/base.py` discovers cases and
manages the test cycle. `suites/c.py` and `suites/asm.py` prepare the two kinds of cases, with z88dk
helpers in `compiler.py`. `emulator.py` collects ZXHost output, `comparison.py` compares screenshots
and data, and `profiles.py` resolves SDK profile layers. Case metadata, reference outputs and
profiles live with each library. The runner builds storage fixtures with
[`fixtures/images.py`](fixtures/images.py). The Z80 runtime and mailbox specification live in
[`lib/test_support`](../../lib/test_support/).

If the C compiler exits with `SIGSEGV`, the runner saves the diagnostics in `build.sigsegv.log` or
`library-build.sigsegv.log` and retries the build once. Ordinary compiler errors are reported
immediately.

The [common suite](../../lib/common/tests/README.en.md) runs one case directory with both machine
adapters and keeps build and result directories separate by machine.

## Running the suites

From the SDK root, run `make test` to run the BaseConf, TSConf, and common suites. The runner needs
Python 3.11 or newer and ZEsarUX with ZRCP. Set `ZESARUX` to select the executable, or let the
runner find it on `PATH` or in a standard installation directory. Set `ZXEVO_TEST_ROM` to override
the ROM used by the `ers-rom` and `ts-bios` profiles.

```sh
make test ZESARUX=/path/to/zesarux ZXEVO_TEST_ROM=/path/to/ZXEVO.ROM
```

Use `make test-baseconf`, `make test-tsconf`, or `make test-common` to run a single suite. Binaries,
manifests, reports and captures go to `tests/build/` under the corresponding library. The common
suite adds machine-specific subdirectories. Run `make clean` from the SDK root to remove build and
test outputs and Python caches. [BaseConf tests](../../lib/baseconf/tests/README.en.md) ·
[TSConf tests](../../lib/tsconf/README.en.md#emulator-tests) ·
[Common tests](../../lib/common/tests/README.en.md)

### Profiles for C and ASM

Define profiles as `[profiles.<name>]` in `profiles.toml`. Set `parent` to inherit another profile.
Use `profile = "stdio+60hz"` or `profiles = ["stdio+60hz"]` for one run with both layers. Each entry
in `profiles` adds a separate run. The runner walks the layers left to right, applying each parent
before its children and each layer once. `--profile` selects the full run name and can be repeated.

The suite's `merge_profile` method merges the ordered settings. Both suites inherit
`[profiles.<name>.layout]` field by field, including `code_org`, `stack_org`, and `code_page`. For
ASM, `code_org` must match the address used to assemble the binary. C combines build options and
reports conflicting assignments. The SDK C profiles inherit from `default`, which is also selected
if the case omits both keys. ASM requires a profile. The `machine` field in a selected or inherited
profile chooses the ZEsarUX machine. All explicit `machine` values in a run must agree. Port writes
are appended in order, including repetitions, and later layers can override mapper settings.

Set `boot_pc` in a profile to stop the ROM at a Z80 address before the runner loads the case. With
`boot_pc`, `boot_cycles` is a positive limit for the ZRCP `run` command, counted in its
instruction-loop iterations. Reaching the limit without the address fails the run. Profiles that
omit `boot_pc` use the fixed startup run. C suites default to 500,000 iterations; the TS-BIOS
profile allows 1,000,000 while waiting for ROM PC `02B0h`, and the BaseConf `ers-rom` profile allows
2,000,000 while waiting for ROM PC `6155h`.

Reference lookup starts in the case's reference directory, then follows the layer order. The full
run name is checked last. For `stdio+60hz`, the profile directories are `default/`, `stdio/`,
`60hz/`, and `stdio+60hz/`, in increasing priority for files with the same name.

### C case profiles and references

Put shared references in `cases/<case-path>/`, where `<case-path>` is the source path without `.c`.
Put changed or additional files under `cases/<case-path>/<profile>/`. An output expected only for
certain runs belongs in their profile directories. Each run stores build artifacts and results in
`tests/build/<case-path>/<profile>/`. In the BaseConf and TSConf suites, `--update` writes shared
files from the first declared profile when no profile-specific reference exists. It writes
differences in the current run's directory and removes overrides that match the inherited file. The
common suite adds the machine name before the profile directory in the reference tree, and before
the case path in the build tree. Its `--update` writes machine-specific overrides.

## Adding a suite

To add a C suite, put its cases and optional matching TOML under its own `tests/cases/`, and put
`profiles.toml` in the suite's `tests/` directory. See the [BaseConf suite](suites/baseconf.py).
Pass the suite's test directory and ZEsarUX machine name to `CTestSuite` and supply these methods.

- `build_target` builds any target library and returns the compiler flags, environment, extra
  sources and inputs that invalidate a cached case. Include the target CRT layout and any library or
  adapter files that affect the linked binary.
- `page_write` encodes a physical RAM page for a CPU window as a port and value.
- `launch_ports` sets up paging, including the resident W1 RAM page and any required W0 ROM. These
  writes run before the loader maps the windows and uploads the manifest blocks.

The shared linker layout expects the mailbox, log and initialized data in W1. Keep that page visible
while the host reads a result, along with the address range of any submitted data. The profile
places code, DATA, BSS and the stack. The runner can split a W0 program across W0 and W1 or load
code wholly inside another window. Use the second form for tests of a ROM API that needs its ROM
mapped in W0.

On the Z80, include `zx_test.h` and call `zx_test_init()` before target-specific initialization. Use
`ZX_ASSERT` and the `zx_test_step_*` functions to report results, and always call
`zx_test_finish()`. The harness starts with interrupts disabled. Individual cases can configure
interrupts once their vectors are ready. The [ZXHost mailbox](#zxhost-target-runtime-and-mailbox)
provides transport for the shared harness.

TSConf cases can put an expected `tsconf_registers` object under a step in `emulator_steps`. Its
keys are hexadecimal `xxAF` register indices and its values are bytes. The runner compares the
emulator's readback while the target is stopped at that step. A `joystick` byte sets the input
before advancing the next step.

### Emulator storage images

Declare each device the C case needs in its TOML. The runner creates the image under the run's
`build/.../<profile>/emulator_images/` directory and attaches it to ZEsarUX with persistent writes
disabled. Image paths in `manifest.json` are relative to the manifest's directory.

```toml
[emulator_images.ide]
fixture = "ers-fat32"
filename = "hdd.img"
size_sectors = 131_072
mount_list = ["E:/DOCS/DISK.TRD C:"]
```

The device keys are `mmc` for SD, `ide` for HDD and `trd` for a Beta Disk image. `ers-fat16`
contains the ERS SD files, `ers-fat32` contains the ERS HDD files, and `ts-fat32` contains the
fragmented file and nested directory used by TS-FAT. For FAT fixtures, `size_sectors` gives the size
of the entire image in 512-byte sectors. The optional `mount_list` writes the listed lines to
`IMAGE.MNT` on `ers-fat32`. The `trd` fixture has a fixed 640 KiB layout and takes only a filename.

## ZXHost target runtime and mailbox

`ZXHost` is the small C runtime/API linked into a program running on the ZX. It publishes a
request/result mailbox and a bounded text log in target memory. It is not the Python controller or
the emulator transport.

[`protocol.json`](../../lib/test_support/protocol.json) defines the header address, layout, states,
version and log range. Generate the C constants before linking a target.

```sh
python3 tools/test_runner/zx_host/generate_header.py \
  lib/test_support/protocol.json build/zx_host_config.h
```

Add `lib/test_support/c` and the generated-header directory to the target include path, then link
`lib/test_support/c/zx_host.c`. The target calls `zx_host_init()` before reading
`zx_host_get_request()`. Initialization preserves the request bytes (command, arguments, sequence
and cancel) published by the controller. The Python request writer clears cancellation for a new
request. The target may poll `zx_host_cancelled()` cooperatively, write result bytes with
`zx_host_set_results()`, append diagnostic text with `zx_host_log_text()`, and finish with one of
`ZX_HOST_DONE`, `ZX_HOST_ABORTED` or `ZX_HOST_ERROR`.

Commands and argument meanings belong to the target program. ZXHost provides the byte transport
contract, not a shared command registry. The sequence byte identifies the request and is written
last by the Python protocol codec; the target preserves it in the completion header.

Test steps can announce their number and name before running. The harness sets `BEGIN` (bit 3) and
`MORE` (bit 1) in `result2` and waits for a new request sequence. The result uses the same step
number and `MORE`, with its output flags and diagnostics. The runner already has the name from
`BEGIN`. A checkpoint that reports its result in one event puts the name in its result log. Final
test completion clears `MORE`.

In C, call `zx_test_step_begin("name")` before the work and pass `NULL` for the name when reporting
the result, for example `zx_test_step_marker(NULL)`.

### SjASMPlus tests

Generate `zx_host_config.inc` from the same `protocol.json` with
`generate_header.py --format sjasmplus`. Include `zx_test.inc` before the test code and include
`zx_host.asm` and `zx_test.asm` from `lib/test_support/z80/` in the assembled binary. After
`CALL zx_test_init`, use `ZX_TEST_BEGIN "name"` before running a step. Finish it with
`ZX_TEST_MARKER`, `ZX_TEST_SHOT`, or `ZX_TEST_DATA address, length, kind`. Set `kind` to `0` for a
hex dump, `1` for text, `2` for a binary file, or `3` for TOML. Pass the status in A and the log
string in HL before jumping to `zx_test_finish`. Set HL to zero to omit a completion message.

For named numeric results, start with `CALL zx_test_output_begin`, add fields with
`ZX_TEST_FIELD "carry", (result_carry)` or `ZX_TEST_FIELD16 "sp", (result_sp)`, and publish with
`ZX_TEST_TOML`. The runner compares the parsed TOML fields with the `.toml` reference file. C cases
can publish the same format with `zx_test_step_toml()`.

Use `python3 tools/test_runner/runner.py asm check --suite-dir … --build-dir … --rom …` to assemble
and run the selected cases. Use `asm build` with the same options to assemble and prepare launch
manifests without running the emulator. The runner uses `sjasmplus` from `PATH` by default. Use
`--sjasmplus` to override it and `--include-dir` to add include paths. The `BUILD` step saves
assembler diagnostics in `<build-dir>/<case>/<profile>/build.log`. Define the launch profiles in
`profiles.toml`. In `cases/<case>/main.toml` beside `main.asm`, use `profile = "tsconf-bios"` for
one run or `profiles = ["tsconf-bios", "tsconf-basic48"]` for multiple runs. An ASM case can combine
profiles with `+` using the same [profile syntax](#profiles-for-c-and-asm).

Reference files use the usual `<case>.<NN>_<tag>.<ext>` names. Put shared files beside `main.toml`
and overrides in directories named after profiles. The same entry point accepts `baseconf`, `tsconf`
or `common` to run the SDK's C suites.

An ASM case can replace code in its test copy of the ROM. Add a `[rom_patch]` table to `main.toml`
with `bank`, `symbol`, and `source`. The runner assembles the replacement source relative to
`main.toml`. To supply a binary, use `file` relative to `<build-dir>/<case>/`. Pass the ROM's
sjasmplus symbol table with `--rom-symbols`.

### Python roles

`tools/test_runner/zx_host/protocol.py` validates and encodes the mailbox descriptor.
`tools/test_runner/zx_host/manifest.py` provides typed launch, block and test-group records and
serializes the program manifest at the JSON boundary. `tools/test_runner/zx_host/basic.py` can build
BASIC POKEs for the startup request from the same descriptor fields.
`tools/test_runner/zx_host/session.py` provides `ZXHostSession`, a host-side session with a ZXHost
target. It loads the blocks listed in a program manifest, sends an initial command, polls for the
matching sequence, reads results and can request cooperative cancellation. `tools/zesarux/runner.py`
remains the emulator transport used internally by that session. A package that remaps the mailbox
after launch may include `runtime_memory` in its manifest; the session checks that the mailbox and
log fit the declared CPU window and bootstrap-to-runtime transfer range.

```python
from tools.test_runner.zx_host import ZXHostSession

with ZXHostSession("build/manifest.json", "/path/to/zesarux") as session:
    session.start(command=1, args=(0, 0))
    result = session.wait_for_completion(timeout=15)
```

`start()` prepares the request and leaves the emulated CPU in CPU-step mode. The caller may inject
keys or call `request_cancel()` before or while advancing the target, then wait for completion.
Close the session through the context manager or `close()`. Call `detach()` only when the emulator
should remain open.
