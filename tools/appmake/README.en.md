# z88dk appmake BaseConf extension

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

This directory contains the project-owned `+baseconf` backend and a small registration patch for
z88dk appmake. It does not vendor upstream appmake sources. To build, provide an existing z88dk
source tree:

```sh
Z88DK_SRC=/path/to/z88dk/src make -C tools/appmake
```

The build script stages the supplied appmake sources under the ignored local `build/` directory,
applies `patches/baseconf-registration.patch`, adds `baseconf.c`, builds the upstream appmake, then
removes the temporary source staging area. The output is `tools/appmake/build/z88dk-appmake`.
`make -C tools/appmake clean` removes that output.

A C compiler, `make`, `patch`, and GMP development files are required. The script uses `pkg-config`
for GMP flags when available and falls back to `-lgmp`. The target tree must have the standard z88dk
layout containing `appmake/`, `common/dirname.{c,h}`, and `config.h`.

## Provenance and license

The backend was developed against z88dk source version `26724-9fc3cae210-20261103`. The script
accepts another compatible source tree through `Z88DK_SRC`; its version is printed during the build.
Upstream appmake source and its original notices are taken from that tree. z88dk's Clarified
Artistic License is in the source tree's parent `LICENSE` file. The registration patch records its
local modification and this repository retains the corresponding project source for the new backend.

## Use

The SDK's BaseConf configuration already sets `APPMAKEEXE` to the local build. In an application
Makefile, include `lib/baseconf/baseconf.mk` from the SDK and pass `-Cz+baseconf` to select this
packer for banked TAP files.

```makefile
	$(ZCC) $(BASECONF_APP_FLAGS) -m -create-app -Cz+baseconf -Cz--name=MYPROGRAM \
	  -o build/program src/main.c
```

To package an existing linked program, invoke the tool directly.

```sh
tools/appmake/build/z88dk-appmake +baseconf \
  --binfile build/program --crt0file build/program --output build/program.tap
```

The linked map and section binaries must follow z88dk appmake naming and be available next to the
supplied base name. The target reads addresses and sizes from the map rather than demo-specific
filenames.

## Target behavior

- Writes a tokenized Spectrum BASIC loader and standard TAP CODE blocks.
- Names the BASIC and main CODE blocks `BASECONF` by default. Pass `--name=NAME` (or zcc
  `-Cz--name=NAME`) to set another program name. Names must contain 1–10 characters and are padded
  to the standard 10-byte TAP field. Bank blocks use `BANK000`–`BANK255` by default; pass
  `--bank-prefix=PREFIX` (or zcc `-Cz--bank-prefix=PREFIX`) to set a 1–7 character prefix. The
  three-digit page number is appended to each prefix.
- Combines initialized main-bank sections into one contiguous image, filling address gaps with zero
  bytes. BSS is excluded from initialized payload.
- Assumes the standard BaseConf ERS/BAS48 startup has configured RAM mode and CPU frequency; the
  BASIC loader does not write `FF77` or `EFF7`. For each `BANK_n` section set, it briefly opens the
  BaseConf shadow port, selects physical page `n` in W3 (`C000–FFFF`) with substitution disabled,
  then restores `BF`. This preserves the ERS tape breakpoint across bank loads. A z80asm `BANK_XX`
  binary with the bank encoded in the high address byte is loaded into the matching physical page.
- Defaults the load origin to the first initialized section and the BASIC `USR` entry to the map
  symbol `start` when present. This distinction matters when initialized DATA is located at `0x7000`
  while `start` remains at `0x8000`. If the map has no `start`, the load origin is used. BASIC CLEAR
  defaults to `0x5fff`. `--org`, `--usraddr`, and `--clearaddr` override these values. `start`
  includes the CRT startup code; do not use `__CODE_head`, which begins after it.
- Combines a bank's sections into one 16 KiB W3 image and loads pages in ascending order.

The main image must fit in the 16-bit address space; each bank must fit W3. Page selection occurs
during BASIC-controlled loading, not while program code is executing.
