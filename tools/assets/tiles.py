"""Split packed images into tiles and build atlases with shared palette indices."""

import json
from pathlib import Path


def _row_bytes(width, height, bits, stride=None):
    if bits not in (1, 4, 8) or width <= 0 or height <= 0:
        raise ValueError("positive dimensions and 1, 4 or 8 bits per pixel required")
    minimum = (width * bits + 7) // 8
    if stride is None:
        return minimum
    if stride < minimum:
        raise ValueError("stride is shorter than a packed row")
    return stride


def _copy_row(source, source_offset, source_x, target, target_offset, target_x, width, bits):
    """Copy pixels between MSB-first rows, including non-byte-aligned tile edges."""
    mask = (1 << bits) - 1
    for x in range(width):
        src_bit = (source_x + x) * bits
        dst_bit = (target_x + x) * bits
        value = (source[source_offset + src_bit // 8] >> (8 - bits - src_bit % 8)) & mask
        target[target_offset + dst_bit // 8] |= value << (8 - bits - dst_bit % 8)


def split_tiles(pixels, *, width, height, tile_width, tile_height, bits=4, stride=None):
    """Return consecutive tiles in row-major order; each tile has compact rows.

    Input is an MSB-first packed bitmap. Dimensions must be multiples of the
    tile dimensions. Source row padding is discarded; tile row padding is zero.
    """
    stride = _row_bytes(width, height, bits, stride)
    tile_stride = _row_bytes(tile_width, tile_height, bits)
    if width % tile_width or height % tile_height:
        raise ValueError("image dimensions must be multiples of tile dimensions")
    if len(pixels) != stride * height:
        raise ValueError("pixel length does not match dimensions and stride")
    output = bytearray((width // tile_width) * (height // tile_height) * tile_stride * tile_height)
    offset = 0
    for y in range(0, height, tile_height):
        for x in range(0, width, tile_width):
            for row in range(tile_height):
                _copy_row(pixels, (y + row) * stride, x, output, offset, 0, tile_width, bits)
                offset += tile_stride
    return bytes(output)


def build_atlas(tiles, *, tile_width, tile_height, columns, rows, bits=4):
    """Place consecutive compact tiles into a fixed grid; unused pixels are zero.

    Tiles fill left-to-right, then top-to-bottom. Reject partial tiles and
    overflow instead of silently dropping data or extending the requested grid.
    """
    tile_stride = _row_bytes(tile_width, tile_height, bits)
    if columns <= 0 or rows <= 0:
        raise ValueError("atlas columns and rows must be positive")
    tile_size = tile_stride * tile_height
    count, remainder = divmod(len(tiles), tile_size)
    if remainder or count > columns * rows:
        raise ValueError("partial tile or atlas capacity exceeded")
    stride = _row_bytes(columns * tile_width, rows * tile_height, bits)
    output = bytearray(stride * rows * tile_height)
    for index in range(count):
        x = (index % columns) * tile_width
        y = (index // columns) * tile_height
        for row in range(tile_height):
            _copy_row(tiles, index * tile_size + row * tile_stride, 0,
                      output, (y + row) * stride, x, tile_width, bits)
    return bytes(output)


def remap_indices(images, *, bits=4, transparent_from=None):
    """Remap byte-per-pixel index buffers to one shared compact index set.

    The input sheets must share the meaning of source indices. This does not
    merge RGB palettes. Reserve destination zero for transparency; source
    indices >= transparent_from are transparent. Return remapped buffers and
    the sorted opaque source indices (destination index minus one indexes it).
    Opaque source zero is retained as an ordinary color.
    """
    if bits not in (1, 4, 8):
        raise ValueError("1, 4 or 8 bits per pixel required")
    if transparent_from is not None and not 0 <= transparent_from <= 256:
        raise ValueError("transparent-from must be in 0..256")
    images = list(images)
    used = sorted({value for pixels in images for value in pixels
                   if transparent_from is None or value < transparent_from})
    if len(used) >= 1 << bits:
        raise ValueError("too many opaque indices for the pixel format with transparent zero")
    mapping = {value: index + 1 for index, value in enumerate(used)}
    return [bytes(mapping.get(value, 0) for value in pixels) for pixels in images], bytes(used)


def convert_atlas(paths, *, tile_width, tile_height, columns, rows, bits=4,
                  transparent_from=None):
    """Load indexed sheets, remap shared indices and assemble a packed atlas.

    Sheets follow input order; tiles within each sheet follow row-major order.
    Transparency is explicit via transparent_from. Alpha-bearing images must
    first be converted to that indexed convention; RGB/animated inputs fail.
    """
    try:
        from PIL import Image
    except ImportError as error:
        raise ValueError("atlas conversion needs Pillow; install tools/assets/requirements.txt") from error
    sheets = []
    dimensions = []
    for path in paths:
        with Image.open(path) as source:
            if source.mode != "P" or getattr(source, "n_frames", 1) != 1:
                raise ValueError(f"{path}: a single-frame indexed image is required")
            if source.convert("RGBA").getchannel("A").getextrema() != (255, 255):
                raise ValueError(f"{path}: encode transparency as palette indices first")
            sheets.append(source.tobytes())
            dimensions.append(source.size)
    if not sheets:
        raise ValueError("at least one indexed sheet is required")
    mapped, colors = remap_indices(sheets, bits=bits, transparent_from=transparent_from)
    tiles = bytearray()
    for pixels, (width, height) in zip(mapped, dimensions):
        stride = _row_bytes(width, height, bits)
        packed = bytearray(stride * height)
        for y in range(height):
            for x in range(width):
                bit = x * bits
                packed[y * stride + bit // 8] |= pixels[y * width + x] << (8 - bits - bit % 8)
        tiles.extend(split_tiles(packed, width=width, height=height, tile_width=tile_width,
                                 tile_height=tile_height, bits=bits))
    atlas = build_atlas(tiles, tile_width=tile_width, tile_height=tile_height,
                        columns=columns, rows=rows, bits=bits)
    count = len(tiles) // (_row_bytes(tile_width, tile_height, bits) * tile_height)
    metadata = dict(width=columns * tile_width, height=rows * tile_height,
                    stride=(columns * tile_width * bits + 7) // 8, bits_per_pixel=bits,
                    tile_width=tile_width, tile_height=tile_height, tile_count=count,
                    columns=columns, rows=rows, transparent_index=0,
                    source_indices=list(colors), unpacked_size=len(atlas), compression="none")
    return atlas, colors, metadata


def register_parser(subparsers):
    tiles = subparsers.add_parser("tiles", help="packed bitmap to consecutive row-major tiles")
    tiles.add_argument("input", type=Path)
    tiles.add_argument("--width", type=int, required=True)
    tiles.add_argument("--height", type=int, required=True)
    tiles.add_argument("--stride", type=int)
    atlas = subparsers.add_parser("atlas", help="indexed sheets to an atlas with shared indices")
    atlas.add_argument("input", type=Path, nargs="+")
    atlas.add_argument("--columns", type=int, required=True)
    atlas.add_argument("--rows", type=int, required=True)
    atlas.add_argument("--transparent-from", type=int)
    for parser, handler in ((tiles, run_tiles), (atlas, run_atlas)):
        parser.add_argument("--output", type=Path, required=True, help="output filename prefix")
        parser.add_argument("--tile-width", type=int, required=True)
        parser.add_argument("--tile-height", type=int, required=True)
        parser.add_argument("--bits", type=int, choices=(1, 4, 8), default=4)
        parser.set_defaults(handler=handler)


def run_tiles(args):
    data = split_tiles(args.input.read_bytes(), width=args.width, height=args.height,
                       tile_width=args.tile_width, tile_height=args.tile_height,
                       bits=args.bits, stride=args.stride)
    metadata = dict(width=args.width, height=args.height, bits_per_pixel=args.bits,
                    tile_width=args.tile_width, tile_height=args.tile_height,
                    tile_stride=(args.tile_width * args.bits + 7) // 8,
                    tile_count=(args.width // args.tile_width) * (args.height // args.tile_height),
                    layout="tiles", unpacked_size=len(data), compression="none")
    return [(Path(str(args.output) + ".bin"), data),
            (Path(str(args.output) + ".json"), (json.dumps(metadata, indent=2) + "\n").encode())]


def run_atlas(args):
    data, colors, metadata = convert_atlas(
        args.input, tile_width=args.tile_width, tile_height=args.tile_height,
        columns=args.columns, rows=args.rows, bits=args.bits, transparent_from=args.transparent_from)
    return [(Path(str(args.output) + ".bin"), data),
            (Path(str(args.output) + ".indices.bin"), colors),
            (Path(str(args.output) + ".json"), (json.dumps(metadata, indent=2) + "\n").encode())]
