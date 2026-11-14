"""Convert raster images to indexed pixels, palettes and metadata."""

import json
import struct
from pathlib import Path

def convert_image(path, *, bits=4, palette_format="rgb222", transparent=False,
                  transparent_from=None, quantize=False, stride=None):
    try:
        from PIL import Image
    except ImportError as error:
        raise ValueError("image conversion needs Pillow; install tools/assets/requirements.txt") from error
    with Image.open(path) as source:
        if getattr(source, "n_frames", 1) != 1:
            raise ValueError("select one frame before converting an animated image")
        source.load()
        width, height = source.size
        rgba = source.convert("RGBA")
        alpha = list(rgba.getchannel("A").tobytes())
        if any(value not in (0, 255) for value in alpha):
            raise ValueError("partial alpha is not supported; flatten or threshold it first")
        source_indices = list(source.tobytes()) if source.mode == "P" else None
        if transparent_from is not None:
            if source_indices is None:
                raise ValueError("--transparent-from requires an indexed image")
            alpha = [0 if index >= transparent_from else a for index, a in zip(source_indices, alpha)]
            transparent = True
        if not transparent and 0 in alpha:
            raise ValueError("image has transparency; use --transparent-zero or flatten it first")
        capacity = (1 << bits) - int(transparent)
        if source_indices is not None and not quantize:
            palette_bytes = source.getpalette("RGB") or []
            palette = [tuple(palette_bytes[i:i + 3]) for i in range(0, len(palette_bytes), 3)]
            indices = source_indices
            if transparent:
                used = sorted({index for index, a in zip(indices, alpha) if a})
                if len(used) > capacity:
                    raise ValueError("too many opaque colors; use --quantize")
                remap = {index: i + 1 for i, index in enumerate(used)}
                palette = [(0, 0, 0)] + [palette[index] for index in used]
                indices = [remap[index] if a else 0 for index, a in zip(indices, alpha)]
            elif max(indices) >= 1 << bits:
                raise ValueError("palette index exceeds pixel format; use --quantize to remap it")
        else:
            rgb = source.convert("RGB")
            if quantize:
                indexed = rgb.quantize(colors=capacity, dither=Image.Dither.NONE)
                rgb = indexed.convert("RGB")
            pixels = list(zip(*[iter(rgb.tobytes())] * 3))
            colors = list(dict.fromkeys(color for color, a in zip(pixels, alpha) if a))
            if len(colors) > capacity:
                raise ValueError(f"image has {len(colors)} colors; use --quantize for {capacity}")
            palette = ([(0, 0, 0)] if transparent else []) + colors
            remap = {color: i + int(transparent) for i, color in enumerate(colors)}
            indices = [remap[color] if a else 0 for color, a in zip(pixels, alpha)]
    palette = palette[:1 << bits]
    palette += [(0, 0, 0)] * ((1 << bits) - len(palette))
    row_bytes = (width * bits + 7) // 8
    stride = row_bytes if stride is None else stride
    if stride < row_bytes:
        raise ValueError("stride is shorter than a packed row")
    output = bytearray(stride * height)
    for y in range(height):
        for x in range(width):
            bit = x * bits
            output[y * stride + bit // 8] |= indices[y * width + x] << (8 - bits - bit % 8)
    colors = bytearray()
    for r, g, b in palette:
        if palette_format == "rgb222":
            colors.append(((r >> 6) << 4) | ((g >> 6) << 2) | (b >> 6))
        elif palette_format == "rgb555":
            colors.extend(struct.pack("<H", ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3)))
        else:
            colors.extend((r, g, b))
    metadata = dict(width=width, height=height, bits_per_pixel=bits, stride=stride,
                    unpacked_size=len(output), palette_format=palette_format,
                    palette_entries=len(palette), palette_size=len(colors),
                    transparent_index=0 if transparent else None, compression="none")
    return bytes(output), bytes(colors), metadata


def register_parser(subparsers):
    parser = subparsers.add_parser("image", help="image to packed pixels, palette and JSON")
    parser.add_argument("input", type=Path)
    parser.add_argument("--output", type=Path, required=True,
                        help="output path prefix, without extension; relative to the current directory")
    parser.add_argument("--format", choices=("mono1", "indexed4", "indexed8"), default="indexed4")
    parser.add_argument("--palette", choices=("rgb222", "rgb555", "rgb888"), default="rgb555")
    parser.add_argument("--stride", type=int, help="bytes per row, including zero padding")
    parser.add_argument("--transparent-zero", action="store_true", help="reserve index zero for alpha=0")
    parser.add_argument("--transparent-from", type=int, help="treat source indices >= N as transparent")
    parser.add_argument("--quantize", action="store_true", help="allow palette reordering/color reduction")
    parser.set_defaults(handler=run)


def run(args):
    if args.transparent_from is not None and not 0 <= args.transparent_from <= 256:
        raise ValueError("transparent-from must be in 0..256")
    pixels, palette, metadata = convert_image(
        args.input, bits={"mono1": 1, "indexed4": 4, "indexed8": 8}[args.format],
        palette_format=args.palette, transparent=args.transparent_zero,
        transparent_from=args.transparent_from, quantize=args.quantize, stride=args.stride)
    return (
        (Path(str(args.output) + ".bin"), pixels),
        (Path(str(args.output) + ".pal.bin"), palette),
        (Path(str(args.output) + ".json"), (json.dumps(metadata, indent=2) + "\n").encode("utf-8")),
    )
