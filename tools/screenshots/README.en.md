# Emulator screenshots

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

`capture.py` loads a built BASIC 48 TAP or TSConf SPG in a separate ZEsarUX process and saves
its screen as PNG. It works with TSConf, BaseConf and Spectrum 48K programs, without any dependency
on the SDK example names or directory layout. Banked TAPs are loaded through their BASIC
loader. The utility does not build programs or run test suites.

Requirements: Python 3 (standard library only) and ZEsarUX with ZRCP support. Select the
emulator through `--zesarux`, the `ZESARUX` environment variable, or PATH. No Pillow is needed.

## Usage

Run from the repository root; input, output and log paths can be anywhere:

```sh
python3 tools/screenshots/capture.py --machine TSConf \
  --tap path/to/program.tap --output build/program.png

python3 tools/screenshots/capture.py --machine BaseConf \
  --tap lib/baseconf/build/examples/night_train.tap --output build/night_train.png

python3 tools/screenshots/capture.py --machine 48K --entry 0x9000 \
  --tap path/to/spectrum.tap --output build/spectrum.png --instructions 500000

python3 tools/screenshots/capture.py --spg path/to/program.spg --output build/program.png
```

`--spg` selects the native ZEsarUX SPG loader through ZRCP `smartload`; it supports the
SpectrumProg 1.0 header and leaves block decompression and initial machine state to the emulator.
Only TSConf is supported for SPG. The entry address comes from the file, so `--entry` cannot
be supplied. BASIC boot/load keys and their delays are skipped. `--instructions`, application
keys and the PNG output work identically for TAP and SPG. This exercises the emulator's loader,
not loading through TS-BIOS from a disk or SD card.

The TAP must contain a BASIC loader that starts the program at `--entry` (default `0x8000`).
The utility boots BASIC, types `LOAD ""`, waits for the entry breakpoint, then lets the program
run for `--instructions` opcodes before taking a screenshot. These counts are **Z80 instructions**,
not T-states, frames or milliseconds. Choose a shorter delay for programs that return to BASIC
automatically, or a longer delay for resource uploads and fades.

For application input, use a semicolon-separated key script:

```sh
python3 tools/screenshots/capture.py --machine TSConf \
  --tap path/to/program.tap --output build/program.png \
  --keys 'enter;h;e;l;l;o;space;w4;right'
```

Letters and digits are supported, along with `space`, `enter`, `caps`, `sym`, `up`, `down`,
`left`, `right`, `load`, `quote` and `break`. `caps+space` holds a chord; `right~100000`
holds a key for a chosen instruction count; `w4` waits four key-settle intervals.
Keys are sent after the initial `--instructions` delay. Capture follows the key script and
`--after-key-instructions` delay. With no `--keys`, the latter delay is skipped.

| Option | Default / purpose |
| --- | --- |
| `--machine` | `TSConf`; also `BaseConf`, `48K` |
| `--tap` / `--spg`, `--output` | One required input and destination PNG; parent directories are created |
| `--entry` | `0x8000`; CPU entry address, decimal or `0x` hexadecimal |
| `--instructions` | `6000000`; execution before application keys or capture |
| `--after-key-instructions` | `500000`; execution after application keys |
| `--boot-instructions` | `2000000`; ROM initialization before startup keys |
| `--load-instructions` | `2000000`; budget to reach the entry after submitting the BASIC command |
| `--key-instructions` | `50000`; key press duration |
| `--key-settle-instructions` | `50000`; execution after key release and unit for `wN` |
| `--startup-keys` | BaseConf: `i;w8`; other machines: empty; override for a different ROM menu |
| `--load-keys` | `load;quote;quote`; keys before the final Enter, which is sent automatically |
| `--rom` | Optional ROM file for the selected machine |
| `--log` | `build/screenshots/<input-name>.log`, relative to the current directory |
| `--zesarux` | Emulator executable |

TSConf startup maps BASIC 48 ROM page 3, disables CPU caching and DOS, and enables the frame
interrupt. BaseConf startup selects BASIC with `i`; Spectrum 48K boots directly to BASIC.
Custom firmware may require different startup/load keys for TAP. The tool supports BASIC 48 TAPs
and TSConf SPG 1.0; it does not launch disk images or other snapshot formats.

Screen capture reuses `tools/zesarux/runner.py`: ZRCP saves a BMP, which is converted losslessly
to PNG using the standard library. The screen retains the emulator's border and native pixel
scaling. Existing output/log files are overwritten; absolute paths are printed on success.
Use distinct `--log` paths when capturing several programs with the same filename.

