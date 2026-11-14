#!/usr/bin/env python3
"""Place XNX assets in physical RAM pages for SPG container compression."""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT))
from tools.assets.image import convert_image
from tools.assets.emit import emit_source
from tools.assets.audio import convert_wav
from tools.assets.pack import emit_pages
from tools.assets.tiles import split_tiles, convert_atlas

ASSETS = Path(__file__).resolve().parent / "assets"
IMAGES = ["title", "font816", *[f"pic{i}" for i in range(1, 11)], "font2432", "bgmask", "textback1"]
PALETTES = ["title", "textback1", *[f"pic{i}" for i in range(1, 11)], "textback2", "textback3"]
MUSIC = ["intro", "level", "loop1", "gameover", "welldone"]
SPRITES = ["player", "titlemask", "spikeball"]


def generate(output):
    output.mkdir(parents=True, exist_ok=True)
    pages = {}
    descriptors = []
    expanded = 0x20
    header = ["/* Generated XNX physical resource layout. */", "#ifndef XNX_ASSETS_H", "#define XNX_ASSETS_H"]

    resource_layout = []
    def store(data, page, name):
        for offset in range(0, len(data), 16384):
            destination = page + offset // 16384
            if destination >= 0xe0 or destination in pages:
                raise ValueError(f"overlapping or invalid physical page {destination:02x}")
            pages[destination] = data[offset:offset + 16384]
        resource_layout.append(dict(name=name, first_page=page, length=len(data)))

    converted = {name: convert_image(ASSETS / 'gfx' / f'{name}.bmp', bits=4, palette_format='rgb222')
                 for name in dict.fromkeys(IMAGES + PALETTES)}
    for name in IMAGES:
        data, _, meta = converted[name]
        width, height = meta['width'], meta['height']
        tiled = split_tiles(data, width=width, height=height, tile_width=8, tile_height=8,
                            bits=4, stride=meta['stride'])
        descriptors.append((expanded, width // 8, height // 8))
        store(tiled, expanded, name)
        expanded += (len(tiled) + 16383) // 16384
    if expanded >= 0x60:
        raise ValueError("expanded tile images overlap the framebuffer")
    header.append("static const image_t images[] = {" + ','.join(
        '{%d,%d,%d}' % desc for desc in descriptors) + "};")
    header.append(emit_source(b''.join(converted[name][1] for name in PALETTES), symbol='palettes'))

    # Use one shared hardware palette for every original sprite. Source
    # indices >=16 are transparent; all opaque indices retain their meaning
    # through sprite_colors[], including opaque source index zero.
    atlas, colors, atlas_meta = convert_atlas(
        [ASSETS / 'gfx' / f'{name}.bmp' for name in SPRITES],
        tile_width=16, tile_height=16, columns=32, rows=4, bits=4, transparent_from=16)
    sprite_count = atlas_meta['tile_count']
    store(atlas, 0x70, 'sprite_atlas')
    header.append(emit_source(colors, symbol='sprite_colors'))
    header.append(f'#define XNX_SPRITE_IMAGES {sprite_count}')

    for name, page in (('start', 0xc0), ('meow', 0xc2)):
        raw, metadata = convert_wav(ASSETS / 'sfx' / f'{name}.wav')
        if metadata['sample_rate'] != 11025:
            raise ValueError('XNX samples require 11025 Hz')
        (output / f'{name}.pcm.json').write_text(json.dumps(metadata, indent=2) + '\n')
        store(raw, page, name)
        header.append(f'#define SAMPLE_{name.upper()}_LENGTH {len(raw)}')
    for name in MUSIC:
        header.append(emit_source((ASSETS / 'mus' / f'{name}.pt3').read_bytes(), symbol=f'music_{name}'))
    header.append('static const void *const music_modules[] = {' + ','.join('music_' + name for name in MUSIC) + '};')
    header.append(emit_source((ASSETS / 'sfx/sounds.afb').read_bytes(), symbol='sound_effects'))
    header.append('#endif')
    (output / 'assets.h').write_text('\n'.join(header) + '\n')
    (output / 'assets.asm').write_text(emit_pages(pages, symbol='xnx_page'))
    (output / 'layout.json').write_text(json.dumps({'expanded_image_end': expanded,
        'physical_pages': len(pages), 'raw_bytes': sum(map(len, pages.values())),
        'sprite_count': sprite_count, 'resources': resource_layout}, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    from tools.python.environment import ensure_environment
    try:
        ensure_environment(ROOT / "tools/assets/requirements.txt")
    except ValueError as error:
        parser.exit(1, f"{error}\n")
    generate(args.output)
