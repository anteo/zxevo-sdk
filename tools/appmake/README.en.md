# z88dk appmake for ZX Evolution

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

The SDK adds the `+baseconf` and `+tsconf` targets to z88dk appmake. Both targets package
banked TAPs. Build the tool from the SDK root with a z88dk source tree.

```sh
make appmake Z88DK_SRC=/path/to/z88dk/src
```

If `ZCCCFG` points to `lib/config` in that tree, `make appmake` finds its `src` directory.
The build stages appmake in the SDK's local build directory and adds `zxevo.c` and
`patches/zxevo-registration.patch`. Both targets are in `tools/appmake/build/z88dk-appmake`.
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

## Pack a TAP

Flat BASIC 48 TAPs use the standard appmake target `+zx` on both machines. BaseConf's
`APPMAKEEXE` points to the local build of appmake. TSConf uses the appmake shipped with z88dk.

For a banked TAP, include the target's Make fragment and add `$(ZX_APPMAKE_BIN)` as a prerequisite
of the TAP rule. Use the application flags and select one appmake target. For BaseConf use
`-Cz+baseconf` with `$(BASECONF_APP_FLAGS)`. For TSConf use `-Cz+tsconf` with
`$(TSCONF_APP_FLAGS)` and put the SDK binary's directory first on `PATH`. For example, a
TSConf recipe can invoke zcc as follows.

```makefile
	PATH="$(dir $(ZX_APPMAKE_BIN)):$$PATH" $(ZCC) $(TSCONF_APP_FLAGS) \
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
  selects the physical page in W3 (`C000–FFFF`) with substitution disabled and restores `BF`
  before each bank load. W3 stays mapped to the last loaded page.
- The TSConf loader saves Page3, maps the bank via port `13AFh`, loads it and restores the
  previous Page3 value.
- Defaults the load origin to the first initialized section and the BASIC `USR` entry to the map
  symbol `start` when present. This distinction matters when initialized DATA is located at `0x7000`
  while `start` remains at `0x8000`. If the map has no `start`, the load origin is used. BASIC CLEAR
  defaults to `0x5fff`. `--org`, `--usraddr`, and `--clearaddr` override these values. `start`
  includes the CRT startup code; do not use `__CODE_head`, which begins after it.
- Combines each bank's sections into a W3 image of up to 16 KiB and loads pages in ascending
  order. For a z80asm `BANK_XX` section, the high address byte encodes the physical page.

The main image must fit in the 16-bit address space. Keep resident code, the BASIC workspace
and its stack accessible during loading. Choose bank pages that are free in the target
configuration.
