"""Compress binary blocks, place them in banks and emit linker-ready sources."""
import json
import subprocess
import tempfile
from pathlib import Path
from .emit import emit_source


def pack_blocks(data, *, chunk_size=2048, compressor='z88dk-zx0'):
    """Return (unpacked offset, unpacked length, ZX0 bytes) for each block."""
    if not data or not 1 <= chunk_size <= 16384:
        raise ValueError('nonempty input and chunk size 1..16384 required')
    blocks = []
    with tempfile.TemporaryDirectory(prefix='zx-assets-') as directory:
        source = Path(directory) / 'block.bin'
        packed = Path(directory) / 'block.zx0'
        for offset in range(0, len(data), chunk_size):
            raw = data[offset:offset + chunk_size]
            source.write_bytes(raw)
            result = subprocess.run([compressor, '-f', str(source), str(packed)],
                                    capture_output=True, text=True)
            if result.returncode:
                raise ValueError(result.stderr.strip() or result.stdout.strip())
            blocks.append((offset, len(raw), packed.read_bytes()))
    return blocks


def pack_banks(blocks, *, first_page=0x80, banks=None):
    """Append indivisible compressed blocks to 16 KiB banks, without padding.

    Existing banks can be reused to coalesce multiple resources. Returned
    descriptors retain exact packed lengths and independent unpacked offsets.
    """
    if not 0 <= first_page <= 255:
        raise ValueError('first page must be 0..255')
    if banks is None:
        banks = [bytearray()]
    if not banks or any(len(bank) > 16384 for bank in banks):
        raise ValueError('existing banks must be nonempty and each at most 16 KiB')
    descriptors = []
    for offset, length, payload in blocks:
        if not payload or len(payload) > 16384:
            raise ValueError('compressed block must fit one 16 KiB bank')
        if len(banks[-1]) + len(payload) > 16384:
            banks.append(bytearray())
        page = first_page + len(banks) - 1
        if page > 255:
            raise ValueError('bank page overflow')
        descriptors.append(dict(page=page, offset=len(banks[-1]), packed_length=len(payload),
                                unpacked_offset=offset, unpacked_length=length))
        banks[-1].extend(payload)
    return banks, descriptors


def emit_banks(banks, *, first_page=0x80, symbol='asset_bank'):
    return '\n'.join(emit_source(data, symbol=f'{symbol}_{first_page+i:02x}', dialect='asm',
        section=f'BANK_{first_page+i:02X}', origin=((first_page+i) << 16) | 0xc000)
        for i, data in enumerate(banks))


def emit_pages(pages, *, symbol='asset_page'):
    """Emit sparse physical 16 KiB pages as z88dk BANK_XX sections."""
    if any(not 0 <= page <= 0xdf or not 1 <= len(data) <= 16384
           for page, data in pages.items()):
        raise ValueError('SPG pages must be 00..DF and contain 1..16384 bytes')
    return '\n'.join(emit_source(pages[page], symbol=f'{symbol}_{page:02x}', dialect='asm',
        section=f'BANK_{page:02X}', origin=(page << 16) | 0xc000)
        for page in sorted(pages))


def register_parser(subparsers):
    parser = subparsers.add_parser('pack', help='binary to independently compressed ZX0 blocks/banks')
    parser.add_argument('input', type=Path)
    parser.add_argument('--output', type=Path, required=True, help='output filename prefix')
    parser.add_argument('--chunk-size', type=int, default=2048)
    parser.add_argument('--first-page', type=lambda s: int(s, 0), default=0x80)
    parser.add_argument('--compressor', default='z88dk-zx0')
    parser.add_argument('--symbol', default='asset_bank')
    parser.set_defaults(handler=run)


def run(args):
    blocks = pack_blocks(args.input.read_bytes(), chunk_size=args.chunk_size, compressor=args.compressor)
    banks, descriptors = pack_banks(blocks, first_page=args.first_page)
    metadata = dict(compression='zx0', page_size=16384, first_page=args.first_page,
                    padding=0, blocks=descriptors)
    result = [(args.output.with_suffix('.json'), (json.dumps(metadata, indent=2)+'\n').encode()),
              (args.output.with_suffix('.asm'), emit_banks(banks, first_page=args.first_page,
                                                         symbol=args.symbol).encode())]
    result.extend((args.output.parent / f'{args.output.name}_{args.first_page+i:02x}.bin', bytes(data))
                  for i, data in enumerate(banks))
    return result
