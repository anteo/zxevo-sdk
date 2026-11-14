#!/usr/bin/env python3
"""Declare demo resources and place raw/ZX0 chunks in 16 KiB banks.

Image conversion and source emission belong to tools/assets. This file only
chooses the original pictures, a 2 KiB decode budget, and physical RAM pages.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from tools.assets.image import convert_image
from tools.assets.emit import emit_source

ASSETS = Path(__file__).resolve().parent / "assets"
PICTURES = {
    "empty": [],
    "font_keyboard": ["font.bmp"],
    "mouse_joystick": ["back.bmp"],
    "sprites": ["back.bmp"],
    "slideshow": [f"pic{i}.bmp" for i in range(1, 6)],
}
SPRITES = {"mouse_joystick": "arrow.bmp", "sprites": "balls.bmp"}


def generate(program, output, compression, compressor):
    output.mkdir(parents=True, exist_ok=True)
    header = ["/* Generated resource placement; see assets.py. */",
              "#ifndef EVOSDK_RESOURCES_H", "#define EVOSDK_RESOURCES_H",
              f"#define RESOURCE_PACKED {int(compression == 'zx0')}"]
    banks = [bytearray()]
    palettes, resources = [], []
    palette_data = {}

    def resource(filename, symbol, sprite=False):
        pixels, palette, metadata = convert_image(
            ASSETS / program / filename, bits=4, palette_format="rgb222",
            transparent_from=16 if sprite else None)
        expected = ((64, 16) if program == "sprites" else (16, 16)) if sprite else (
            (128, 32) if program == "font_keyboard" else (320, 200))
        if (metadata['width'], metadata['height']) != expected:
            raise ValueError(f"unexpected dimensions: {filename}")
        if sprite and program == "mouse_joystick":
            # The original arrow uses indices 0 and 15 from PAL_BACK, not
            # its own BMP palette. Conversion remaps them to opaque 1 and 2.
            background = palette_data['image0']
            palette = bytes([0, background[0], background[15]] + [0] * 13)
        palette_data[symbol] = palette
        (output / f"{symbol}.bin").write_bytes(pixels)
        (output / f"{symbol}.pal.bin").write_bytes(palette)
        (output / f"{symbol}.json").write_text(json.dumps(metadata, indent=2) + "\n")
        header.append(emit_source(palette, symbol=f"{symbol}_palette"))
        row_bytes = metadata['stride']
        rows_per_chunk = 2048 // row_bytes
        chunks = []
        for row in range(0, metadata['height'], rows_per_chunk):
            rows = min(rows_per_chunk, metadata['height'] - row)
            data = pixels[row * row_bytes:(row + rows) * row_bytes]
            if compression == 'zx0':
                source = output / f"{symbol}_{row}.bin"
                packed = source.with_suffix('.zx0')
                source.write_bytes(data)
                subprocess.run([compressor, '-f', str(source), str(packed)], check=True,
                               stdout=subprocess.DEVNULL)
                data = packed.read_bytes()
            if len(banks[-1]) + len(data) > 0x4000:
                banks.append(bytearray())
            page = 0x80 + len(banks) - 1
            if page >= 0xb0:
                raise ValueError("resources overlap the sprite atlas")
            chunks.append((page, len(banks[-1]), rows))
            banks[-1].extend(data)
        header.append(f"static const resource_chunk_t {symbol}_chunks[] = {{")
        header.extend(f"    {{{page}, {offset}, {rows}}}," for page, offset, rows in chunks)
        header.append("};")
        return f"{{{symbol}_chunks, {len(chunks)}, {row_bytes}}}"

    for index, filename in enumerate(PICTURES[program]):
        resources.append(resource(filename, f"image{index}"))
        palettes.append(f"image{index}_palette")
    if resources:
        header.append("static const image_resource_t image_resources[] = {" + ", ".join(resources) + "};")
        header.append("static const uint8_t *const image_palettes[] = {" + ", ".join(palettes) + "};")
    if program in SPRITES:
        descriptor = resource(SPRITES[program], "sprite", True)
        header.append(f"static const image_resource_t sprite_resource = {descriptor};")
    header.append("#endif")
    assembly = []
    for i, data in enumerate(banks):
        if data:
            page = 0x80 + i
            assembly.append(emit_source(data, symbol=f"resource_bank_{page:02x}", dialect='asm',
                                        section=f"BANK_{page:02X}", origin=(page << 16) | 0xc000))
    (output / "resources.asm").write_text("\n".join(assembly) + "\n")
    (output / "resources.h").write_text("\n".join(header) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("program", choices=PICTURES)
    parser.add_argument("output", type=Path)
    parser.add_argument("--compression", choices=('none', 'zx0'), default='zx0')
    parser.add_argument("--compressor", default='z88dk-zx0')
    args = parser.parse_args()
    from tools.python.environment import ensure_environment
    try:
        if args.program != "empty":
            ensure_environment(ROOT / "tools/assets/requirements.txt")
    except ValueError as error:
        parser.exit(1, f"{error}\n")
    generate(args.program, args.output, args.compression, args.compressor)
