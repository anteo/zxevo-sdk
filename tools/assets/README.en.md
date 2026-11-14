# Asset tools

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

`convert.py` converts PNG, BMP, JPEG and other single-frame formats supported by Pillow into
packed pixels and a palette. It also emits **any binary file** as C or z88dk ASM. Conversion,
compression and source emission are independent steps; the Z80 never decodes PNG/BMP files.
Only image conversion is graphics-specific. Compression and source emission also work with
music, level maps, text, tables and other binary resources. Compression uses external z88dk
tools; `convert.py` provides `image`, `tiles`, `atlas`, `wav`, `emit` and `pack` commands.

The CLI entry point registers commands, dispatches their handlers and writes the returned
artifacts. Each module owns its conversion logic, arguments and handler:

| Module | Responsibility |
| --- | --- |
| `convert.py` | Command registration, dispatch, file writing and path/size reporting |
| `image.py` | `image`: raster images to indexed pixels and palettes |
| `tiles.py` | `tiles` / `atlas`: tile ordering, shared index remapping and atlas assembly |
| `audio.py` | `wav`: PCM WAV to unsigned 8-bit mono |
| `emit.py` | `emit`: arbitrary binary data to C/ASM |
| `pack.py` | `pack`: binary ZX0 blocks, bank placement, ASM/JSON emission |

Build scripts import `convert_image` from `tools.assets.image`, `convert_wav` from
`tools.assets.audio`, and `emit_source` from `tools.assets.emit` directly.

With Python 3.11+ available, run directly from the repository root:

```sh
./tools/assets/convert.py image picture.png \
  --output build/picture --format indexed4 --palette rgb555
```

No venv activation, pip command or Make variable is needed. On the first `image`
or `atlas` invocation, the shared [Python launcher](../python/README.en.md) creates
`tools/assets/build/python-requirements`, installs the declared dependencies there,
then restarts the command. Initial setup needs network access (or a populated pip
cache/local package index). Further runs reuse it; changing `requirements.txt` or
the Python runtime triggers setup again. Setup messages go to stderr.
`--help`, `wav`, `tiles`, `emit` and `pack` do not prepare a Python environment.
`pack` still requires the external z88dk compressor.

The example asset recipes use the same launcher, so both `make examples-xnx` and
`make` in the XNX directory work with the default `python3`. Conversion functions
imported as a library do not install anything; a custom CLI can call
`ensure_environment()` before using them.

This creates `build/picture.bin`, `build/picture.pal.bin` and `build/picture.json`.
All commands print the absolute path and byte size of each file they create.
Relative output paths are resolved from the current working directory, not the input image's
directory. In `image`, `--output c` means the filename prefix `c`, producing `c.bin`,
`c.pal.bin` and `c.json`; to generate C source, use the separate `emit` command.
The JSON records dimensions, row stride, pixel depth, palette format, transparency and unpacked
length. Indexed images retain their palette indices by default. True-color images with too many
colors require explicit `--quantize`; color reduction and palette reordering are never implicit.
Palette channels are truncated to the selected hardware precision.

| Option | Layout |
| --- | --- |
| `--format mono1` | Eight indices per byte, leftmost pixel in bit 7; not Spectrum screen interleave |
| `--format indexed4` | Two indices per byte, left pixel in bits 7:4 |
| `--format indexed8` | One index per byte |
| `--stride N` | Row stride in bytes, zero padding after the visible pixels |
| `--palette rgb222` | One byte per color, `00RRGGBB` |
| `--palette rgb555` | Little-endian words, `0RRRRRGGGGGBBBBB` for TSConf CRAM |
| `--palette rgb888` | Three bytes per color, RGB |
| `--transparent-zero` | Reserve index 0 for fully transparent pixels; remap opaque colors to 1… |
| `--transparent-from 16` | Legacy indexed sprites: source indices ≥16 are transparent |

Rows are top-to-bottom, pixels left-to-right. The final byte of an incomplete row is padded with
zero bits. Semi-transparent pixels and animated images are rejected; flatten/threshold alpha or
select a frame first. These are resource layouts, not a universal framebuffer layout: ATM 320,
ZX screen interleave and tile/sprite atlases still require the appropriate destination layout.
TSConf examples transfer compact rows with DMA, which supplies the hardware stride.

## Tiles and atlases

`tiles` rearranges a packed bitmap into consecutive tiles, left-to-right and then
top-to-bottom. It accepts 1/4/8 bpp, with the leftmost pixel in the high bits, and
optional source row padding. Image dimensions must be multiples of the tile dimensions.
Every tile has compact rows; unused bits in its last row byte are zero.

```sh
./tools/assets/convert.py tiles build/picture.bin --width 320 --height 200 \
  --tile-width 8 --tile-height 8 --bits 4 --output build/picture_tiles
```

This writes `.bin` and `.json`. Feed the binary to `pack` or `emit` as usual.

`atlas` reads single-frame indexed images, splits them into tiles and places them
in a fixed grid. Input file order and row-major tile order are retained. Unused
cells are zero; incomplete tiles and atlas overflow are errors.

```sh
./tools/assets/convert.py atlas player.bmp effects.bmp \
  --tile-width 16 --tile-height 16 --columns 32 --rows 4 --bits 4 \
  --transparent-from 16 --output build/sprites
```

The result is `.bin`, `.indices.bin` and `.json`. The atlas reserves index zero
for transparency. `--transparent-from 16` treats source indices 16 and above as
transparent. Opaque indices from all sheets are sorted and mapped together to
1…N, preserving opaque source zero. All sheets must use the same meaning for
each source index: this combines **indices, not RGB palettes**. RGB images,
alpha transparency and animated inputs must be converted beforehand. An atlas
with `--bits 4` can contain at most 15 distinct opaque source indices.

`.indices.bin` stores the original index for each opaque output index: its byte
at offset `output_index - 1` selects the original palette entry. The same list
is in JSON as `source_indices`; it is not an RGB palette. Without
`--transparent-from`, all used source indices are opaque and zero is still
reserved in the output.

Python recipes can import `split_tiles`, `build_atlas`, `remap_indices` and
`convert_atlas` from `tools.assets.tiles`. `split_tiles` returns a tile byte
stream; `build_atlas` arranges such a stream into a grid. `remap_indices` accepts
byte-per-pixel index buffers and returns remapped buffers plus the source-index
table. `convert_atlas` handles indexed image loading and returns atlas bytes,
the source-index table and metadata. Only image loading requires Pillow.

## WAV audio

Convert uncompressed 8/16-bit mono/stereo PCM WAV to unsigned 8-bit mono bytes:

```sh
./tools/assets/convert.py wav start.wav --output build/start
./tools/assets/convert.py emit build/start.bin --metadata build/start.json \
  --symbol start_sample --output build/start.h
```

This writes `.bin` and `.json` with sample rate, sample count, channel count and sample depth.
The rate is preserved; there is no resampling. Stereo is averaged and 16-bit samples are reduced
to eight bits. Mono PCM8 is preserved byte for byte, including zero-valued samples. `wav` uses
only the standard library. `emit` exports the audio metadata as constants alongside the bytes.
PCM8 can be passed directly to `zx_covox_play(samples, count, delay)`.
`zx_pcm8_play_banked` streams consecutive physical RAM pages through a caller-selected
window and restores its mapping and IFF. The caller controls CPU speed and cache.

## Compression and source emission

Use the existing z88dk compressor on the **binary**, then emit source from its output:

```sh
z88dk-zx0 -f build/picture.bin build/picture.zx0
./tools/assets/convert.py emit build/picture.zx0 \
  --metadata build/picture.json --compression zx0 \
  --symbol picture --output build/picture.h

./tools/assets/convert.py emit build/picture.zx0 \
  --metadata build/picture.json --compression zx0 --language asm \
  --symbol picture --section BANK_80 --origin 0x80c000 --output build/picture.asm
```

`emit` needs only Python's standard library. C output is a guarded header with a `uint8_t` array
and size/dimension constants. ASM output exports both `picture` and `_picture`, emits bytes,
and exports the size/dimension constants. A resource placed in `BANK_XX` must fit in one 16 KiB
bank; split larger resources before compression. The example resource builder demonstrates
independent blocks with a fixed maximum unpacked size.

For uncompressed data, omit `--compression`. Palette files can be emitted separately with another
symbol. The image JSON describes the **pixel** stream, so do not pass it when emitting the palette.
ZX7 is also usable: run `z88dk-zx7` externally and specify `--compression zx7` at emission.
Compression metadata is explicit; the emitter does not guess a format from binary bytes.
For a compressed non-image resource, supply a JSON file containing its original byte length,
for example `{"unpacked_size": 4096}`. Graphics fields are optional. Uncompressed binary
resources do not require metadata:

```sh
./tools/assets/convert.py emit level.bin --symbol level --output build/level.h
```

## Decompression in SDK applications

Both SDK targets use z88dk classic and can link its existing decompression routines:

```c
#include <compress/zx0.h>
#include "picture.h"

/* destination must have PICTURE_UNPACKED_SIZE writable bytes. */
dzx0_standard((void *)picture, destination);
```

Use `z88dk-zx0`'s default **ZX0 v2** output with the matching current z88dk decoder; do not use
the `-c` classic-v1 switch. For ZX7 use `<compress/zx7.h>` and `dzx7_standard()` instead.
No duplicate decoder or SDK compatibility wrapper is needed. The codecs' original licenses
remain in z88dk.

The decoders have no length parameter and do not validate compressed input. Use build-generated
resources, reserve the recorded output length, keep both buffers CPU-visible and non-overlapping,
and do not change their mappings mid-call. An interrupt handler must preserve those mappings.
Decompression is a CPU operation; only the subsequent copy to video memory uses DMA.

TSConf DMA requires even source/destination byte addresses and an even burst length. A C
`uint8_t` array is not necessarily aligned: for a 2048-byte decode buffer allocate 2049 bytes
and round its pointer up to the next even address. Split DMA transfers at CPU-window boundaries
when their resident physical pages are not consecutive. Compressed input itself need not be aligned.

## Binary block and bank packing

`pack` accepts binary data, not generated C/ASM. It compresses independent ZX0 blocks,
places them into 16 KiB banks and emits ASM `BANK_XX` sections, bank binaries and JSON
with exact packed/unpacked lengths and offsets. Banks have no implicit padding.

```sh
./tools/assets/convert.py pack image.bin --output build/image --chunk-size 2048 --first-page 0x80
```

The same `pack_blocks`, `pack_banks` and `emit_banks` helpers are used by the XNX asset recipe.
That recipe retains resource lists/order, tile and atlas dimensions, transparency
settings, destination pages and game tables. `tiles.py` performs tile extraction,
shared index remapping and atlas assembly; `pack.py` owns compression and bank placement.

