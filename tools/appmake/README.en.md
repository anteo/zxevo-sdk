# z88dk appmake for ZX Evolution

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

The SDK adds the `+baseconf` and `+tsconf` targets to z88dk appmake. Both targets package banked
TAPs; `+tsconf --format=spg` also creates SPG programs. Build the tool from the SDK root with a
z88dk source tree.

```sh
make appmake Z88DK_SRC=/path/to/z88dk/src
```

If `ZCCCFG` points to `lib/config` in that tree, `make appmake` finds its `src` directory. The build
stages appmake in the SDK's local build directory and adds `zxevo.c` and
`patches/zxevo-registration.patch`. Both targets are in `tools/appmake/build/z88dk-appmake`. The
build also prepares the separate [mhmt tool](../mhmt/README.en.md) in `tools/mhmt/build/`.
`make -C tools/appmake clean` removes the local build.

A C compiler, `make`, `patch`, and GMP development files are required. The script uses `pkg-config`
for GMP flags when available and falls back to `-lgmp`. The target tree must have the standard z88dk
layout containing `appmake/`, `common/dirname.{c,h}`, and `config.h`.

## Provenance and license

The backend was developed against z88dk source version `26724-9fc3cae210-20261103`. The script
accepts another compatible source tree through `Z88DK_SRC`; its version is printed during the build.
Upstream appmake source and its original notices are taken from that tree. z88dk's Clarified
Artistic License is in the source tree's parent `LICENSE` file. The registration patch records its
local modification and this repository retains the corresponding project source for the new backend.
The bundled `mhmt` source is licensed separately under GPLv3 and runs as a separate executable.

## Pack a TAP

Both configurations select the SDK appmake through `APPMAKEEXE`. Flat BASIC 48 TAPs use its standard
target `+zx`. When building TAPs from a Makefile, include the target's Make fragment and add
`$(ZX_APPMAKE_BIN)` as a prerequisite of the TAP rule.

For a banked TAP, use `-Cz+baseconf` with `$(BASECONF_APP_FLAGS)` or `-Cz+tsconf` with
`$(TSCONF_APP_FLAGS)`. A TSConf recipe can invoke zcc as follows.

```makefile
	$(ZCC) $(TSCONF_APP_FLAGS) \
	  -pragma-define:CRT_ORG_CODE=0x8000 -m -create-app -Cz+tsconf \
	  -Cz--name=MYPROGRAM -o build/program src/main.c
```

Add the linker settings for your RAM banks. To use the BASIC 48 CRT and return to BASIC, add
`-crt0=$(ZX_COMMON_ROOT)/crt/basic48_crt0.asm` to the application flags. The `*_BASIC48_FLAGS`
variables already select `+zx` for flat TAPs, so use `*_APP_FLAGS` as the base for banked builds.

To package an existing linked program, invoke the tool directly with `+baseconf` or `+tsconf`.

```sh
tools/appmake/build/z88dk-appmake +tsconf \
  --binfile build/program --crt0file build/program --output build/program.tap
```

The linked map and section binaries must follow z88dk appmake naming and be available next to the
supplied base name. The target reads addresses and sizes from the map rather than demo-specific
filenames.

## Pack an SPG

SPG is a directly launched TSConf program with physical RAM blocks and startup registers. Use
`+tsconf --format=spg`; selecting the output extension alone does not change the format. The same
map and section binaries used for TAP packaging supply the data:

```sh
tools/appmake/build/z88dk-appmake +tsconf --format=spg \
  --binfile build/program --crt0file build/program --output build/program.spg \
  --name=MYPROGRAM --spg-stack=0x8000 --spg-page3=0 --spg-resident=0x5b00 \
  --spg-compression=auto
```

Build a standalone application with the shared Z80 CRT selected by `TSCONF_APP_FLAGS`:

```makefile
program.spg: src/main.c $(TSCONF_LIB) $(ZX_APPMAKE_BIN)
	$(ZCC) $(TSCONF_APP_FLAGS) -pragma-define:CRT_ORG_CODE=0x8000 \
	  -pragma-define:CRT_ENABLE_STDIO=0 -m -create-app -Cz+tsconf \
	  -Cz--format=spg -Cz--spg-stack=0x8000 -Cz--spg-page3=0 \
	  -Cz--name=MYPROGRAM -o program src/main.c
```

Do not select `*_BASIC48_FLAGS` or `basic48_crt0.asm`: SPG does not enter through BASIC `USR` and
provides no BASIC return address. Repackaging a BASIC-return TAP does not make its startup contract
suitable for SPG. The shared standalone CRT preserves the SP supplied by the SPG header unless the
application overrides its stack setting; its default exit behavior is a halt loop. The loader
supplies BASIC 48 ROM in W0, RAM page 5 in W1, page 2 in W2, the selected page in W3, ZX screen 0,
IM1 and I=3Fh. This does **not** initialize a BASIC session or its workspace. The application must
initialize its video/palette/TSU state, peripheral settings and interrupt handler before enabling
interrupts. Leave interrupts disabled at entry unless the application has explicitly arranged a
valid handler and its required memory. Calls to the BASIC IM1 handler, ROM I/O, or an unconditional
`RET` cannot assume the TAP launch environment.

| Option              | Default / meaning                                                                             |
| ------------------- | --------------------------------------------------------------------------------------------- |
| `--format=spg`      | SPG 1.0 output; available only with `+tsconf`                                                 |
| `--name`            | `TSCONF`; description field, 1–32 bytes                                                       |
| `--usraddr`         | Map symbol `start`, otherwise the first initialized address; CPU entry must be in `4000–FFFF` |
| `--spg-stack`       | `0x8000`; initial SP, with the stack growing downward                                         |
| `--spg-page3`       | `0`; physical RAM page mapped at `C000–FFFF` on entry, range `00–DF`                          |
| `--spg-resident`    | `0x5b00`; reserve 16 bytes for the loader resident                                            |
| `--spg-clock`       | `0`: 3.5 MHz; `1`: 7 MHz; `2`: 14 MHz; `3`: upstream 14+ mode                                 |
| `--spg-interrupts`  | Enable interrupts at entry; disabled by default                                               |
| `--spg-compression` | `none` (default), `auto`, `mlz` or `hrust`; `auto` tries both formats per page                |
| `--spg-compressor`  | Built `tools/mhmt/build/mhmt` by default; override the executable path                        |

The writer splits the resident load image at CPU window boundaries and maps it to physical pages 5,
2 and `--spg-page3`. `BANK_XX` resources retain their explicit physical pages. Each occupied page
becomes one block, aligned and padded with zeroes to 512-byte sectors. With compression enabled,
appmake calls `mhmt` for each occupied page, records the SPG-native MegaLZ/Hrust type, and keeps a
raw block if compression does not save a complete sector. `auto` picks the smallest sector count,
preferring MegaLZ on a tie. Appmake uses the locally built `mhmt` when invoked through its SDK path;
`--spg-compressor` can select another build. The SPG loader decompresses these blocks before
entering the application, so code and PT3 modules keep their linked addresses. Address gaps within a
block are zero-filled. Overlapping resident/bank data is rejected, as are pages `E0–FF`, which SPG
reserves for the loader. BSS is omitted. The loader resident and first stack word must avoid
initialized data (including sector padding) and BSS. Reserve enough additional space below SP for
the complete application stack; the packager cannot infer its depth. No optional pager is installed
(`pager=0`). The header uses the fixed date 2000-01-01 00:00:00 for reproducible output. Output
defaults to the input stem with `.spg`. For SPG, `--org` must match the linked load origin. Relink
with the desired `CRT_ORG_CODE` to move the program: changing a load address alone does not relocate
absolute references or BSS.

Raw resources in `BANK_XX` sections can be compressed by the SPG container without an application
decoder. Already compressed ZX0/ZX7 resources remain compressed bytes within their blocks and still
require the application's decoder. SPG 1.1 picture/RO/RW extensions are not emitted. `--clearaddr`
and `--bank-prefix` apply only to TAP and are rejected for SPG.

The layout follows `pentevo/docs/Formats/SPGv1_0.txt` and the original `spgbld` in the
[TSConf repository](https://github.com/tslabs/zx-evo/tree/f0eebed4edb4f36d0e6368363376b317f5a83083/pentevo).
This implementation writes the format directly; it does not invoke the Windows SPG builder.

## Test banked TAPs

Run the appmake suite separately from the library tests.

```sh
make test-appmake ZESARUX=/path/to/zesarux ZXEVO_TEST_ROM=/path/to/ZXEVO.ROM
```

The suite builds a banked TAP with each target and runs `LOAD ""` in BASIC 48. It checks the bytes
in both physical RAM pages, the W3 mapping at entry and the return to BASIC. Test TAPs, build logs
and emulator logs are under `tools/appmake/build/tests/`. Omit `ZXEVO_TEST_ROM` to use the ROMs
provided by the emulator.

## Target behavior

- Writes a tokenized Spectrum BASIC loader and standard TAP CODE blocks.
- Names the BASIC and main CODE blocks `BASECONF` or `TSCONF` by default. Pass `--name=NAME` (or zcc
  `-Cz--name=NAME`) to set another program name. Names must contain 1–10 characters and are padded
  to the standard 10-byte TAP field. Bank blocks use `BANK000`–`BANK255` by default; pass
  `--bank-prefix=PREFIX` (or zcc `-Cz--bank-prefix=PREFIX`) to set a 1–7 character prefix. The
  three-digit page number is appended to each prefix.
- Combines initialized main-bank sections into one contiguous image, filling address gaps with zero
  bytes. BSS is excluded from initialized payload.
- The BaseConf loader uses the RAM and CPU settings from ERS/BAS48. It opens the shadow ports,
  selects the physical page in W3 (`C000–FFFF`) with substitution disabled and restores `BF` before
  each bank load. W3 stays mapped to the last loaded page.
- The TSConf loader saves Page3, maps the bank via port `13AFh`, loads it and restores the previous
  Page3 value.
- Defaults the load origin to the first initialized section and the BASIC `USR` entry to the map
  symbol `start` when present. This distinction matters when initialized DATA is located at `0x7000`
  while `start` remains at `0x8000`. If the map has no `start`, the load origin is used. BASIC CLEAR
  defaults to `0x5fff`. `--org`, `--usraddr`, and `--clearaddr` override these values. `start`
  includes the CRT startup code; do not use `__CODE_head`, which begins after it.
- Combines each bank's sections into a W3 image of up to 16 KiB and loads pages in ascending order.
  For a z80asm `BANK_XX` section, the high address byte encodes the physical page.

The main image must fit in the 16-bit address space. Keep resident code, the BASIC workspace and its
stack accessible during loading. Choose bank pages that are free in the target configuration.
