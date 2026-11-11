# ZX Evolution test support

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

`runner.py` builds C cases with z88dk, loads the linked blocks through ZEsarUX and ZXHost, and
compares screenshots, text and binary output. Case metadata, reference outputs, machine-specific
profiles and fixtures live with each library.

If the C compiler exits with `SIGSEGV`, the runner saves the diagnostics in `build.sigsegv.log` or
`library-build.sigsegv.log` and retries the build once. Ordinary compiler errors are reported
immediately.

The [common suite](../common/tests/README.en.md) runs one case directory with both machine adapters
and keeps build and result directories separate by machine.

## Running the suites

From the SDK root, run `make test` to run the BaseConf, TSConf, and common suites. The runner needs
Python 3 and ZEsarUX with ZRCP. Set `ZESARUX` to select the executable, or let the runner find it
on `PATH` or in a standard installation directory. Set `ZXEVO_TEST_ROM` to override the ROM used
by the `ers-rom` and `ts-bios` profiles.

```sh
make test ZESARUX=/path/to/zesarux ZXEVO_TEST_ROM=/path/to/ZXEVO.ROM
```

Use `make test-baseconf`, `make test-tsconf`, or `make test-common` to run a single suite. Binaries
and manifests go to `tests/build/`, and reports and captures go to `tests/out/` under the
corresponding library. The common suite adds machine-specific subdirectories. Run `make clean`
from the SDK root to remove build and test outputs and Python caches.
[BaseConf tests](../baseconf/tests/README.en.md) ·
[TSConf tests](../tsconf/README.en.md#emulator-tests) ·
[Common tests](../common/tests/README.en.md)

## Adding a suite

To add a suite, put its C cases and optional matching JSON under its own `tests/cases/`. Put
`profiles.json` and a short entry point in the suite's `tests/` directory. See the
[BaseConf adapter](../baseconf/tests/run.py). Pass the suite's test directory and ZEsarUX machine
name to `TestSuite` and supply these methods.

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
before advancing the next step. An `emulator_images.trd` entry attaches a generated TRD image with
persistent writes disabled.

## ZXHost target runtime and mailbox

`ZXHost` is the small C runtime/API linked into a program running on the ZX. It publishes a
request/result mailbox and a bounded text log in target memory. It is not the Python controller or
the emulator transport.

`protocol.json` is the source of truth for the header address, layout, states, version and log
range. Generate the C constants before linking a target:

```sh
python3 tools/zesarux/zx_host/generate_header.py \
  lib/test_support/protocol.json build/zx_host_config.h
```

Add `lib/test_support/include` and the generated-header directory to the target include path, then
link `lib/test_support/src/zx_host.c`. The target calls `zx_host_init()` before reading
`zx_host_get_request()`. Initialization preserves the request bytes (command, arguments, sequence
and cancel) published by the controller. The Python request writer clears cancellation for a new
request. The target may poll `zx_host_cancelled()` cooperatively, write result bytes with
`zx_host_set_results()`, append diagnostic text with `zx_host_log_text()`, and finish with one of
`ZX_HOST_DONE`, `ZX_HOST_ABORTED` or `ZX_HOST_ERROR`.

Commands and argument meanings belong to the target program. ZXHost provides the byte transport
contract, not a shared command registry. The sequence byte identifies the request and is written
last by the Python protocol codec; the target preserves it in the completion header.

### Python roles

`tools/zesarux/zx_host/protocol.py` validates and encodes the mailbox descriptor.
`tools/zesarux/zx_host/manifest.py` provides typed launch, block and test-group records and
serializes the program manifest at the JSON boundary. `tools/zesarux/zx_host/basic.py` can build
BASIC POKEs for the startup request from the same descriptor fields.
`tools/zesarux/zx_host/session.py` provides `ZXHostSession`, a host-side session with a ZXHost
target. It loads the blocks listed in a program manifest, sends an initial command, polls for the
matching sequence, reads results and can request cooperative cancellation. `tools/zesarux/runner.py`
remains the emulator transport used internally by that session. A package that remaps the mailbox
after launch may include `runtime_memory` in its manifest; the session checks that the mailbox and
log fit the declared CPU window and bootstrap-to-runtime transfer range.

```python
from tools.zesarux.zx_host import ZXHostSession

with ZXHostSession("build/manifest.json", "/path/to/zesarux") as session:
    session.start(command=1, args=(0, 0))
    result = session.wait_for_completion(timeout=15)
```

`start()` prepares the request and leaves the emulated CPU in CPU-step mode. The caller may inject
keys or call `request_cancel()` before or while advancing the target, then wait for completion.
Close the session through the context manager or `close()`. Call `detach()` only when the emulator
should remain open.
