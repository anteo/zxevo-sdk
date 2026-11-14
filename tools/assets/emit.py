"""Emit arbitrary binary resources as C headers or z88dk ASM."""

import json
import re
from pathlib import Path

def identifier(value):
    if not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", value):
        raise ValueError(f"invalid C/ASM identifier: {value}")
    return value


def emit_source(data, *, symbol, dialect="c", metadata=None, compression="none",
                section="rodata_user", origin=None):
    symbol = identifier(symbol)
    metadata = metadata or {}
    values = {"size": len(data)}
    for key in ("unpacked_size", "width", "height", "bits_per_pixel", "stride", "transparent_index",
                "sample_count", "sample_rate", "channels", "bits_per_sample"):
        if key in metadata:
            value = metadata[key]
            if key == "transparent_index" and value is None:
                continue
            if type(value) is not int or value < 0:
                raise ValueError(f"metadata {key} must be a nonnegative integer")
            values[key] = value
    if compression != "none" and "unpacked_size" not in values:
        raise ValueError("compressed resources require metadata with unpacked_size")
    if compression == "none":
        if values.get("unpacked_size", len(data)) != len(data):
            raise ValueError("binary length differs from metadata; specify --compression if packed")
        values["unpacked_size"] = len(data)
    if not data:
        raise ValueError("cannot emit an empty resource")
    comment = f"Generated binary resource; compression={compression}."
    if dialect == "c":
        if origin is not None:
            raise ValueError("--origin is only available with ASM output")
        if len(data) > 65535:
            raise ValueError("resource exceeds the Z80 address space; split it before source emission")
        upper = symbol.upper()
        lines = [f"/* {comment} */", f"#ifndef {upper}_RESOURCE_H", f"#define {upper}_RESOURCE_H",
                 "#include <stdint.h>", ""]
        lines += [f"#define {upper}_{key.upper()} {value}UL" for key, value in values.items()]
        lines += [f"#define {upper}_COMPRESSION_{compression.upper()} 1",
                  f"static const uint8_t {symbol}[{len(data)}] = {{"]
        for offset in range(0, len(data), 16):
            lines.append("    " + ", ".join(f"0x{byte:02x}" for byte in data[offset:offset + 16]) + ",")
        lines += ["};", "#endif", ""]
    else:
        section = identifier(section)
        lines = [f"; {comment}", f"SECTION {section}"]
        if origin is not None:
            if origin < 0 or origin > 0xffffff:
                raise ValueError("origin is outside the z80asm bank address range")
            if section.startswith("BANK_") and (origin & 0x3fff) + len(data) > 0x4000:
                raise ValueError("resource crosses a 16 KiB bank; split it before source emission")
            lines.append(f"ORG 0x{origin:x}")
        lines += [f"PUBLIC {symbol}", f"PUBLIC _{symbol}", f"{symbol}:", f"_{symbol}:"]
        for offset in range(0, len(data), 16):
            lines.append("    defb " + ",".join(f"0x{byte:02x}" for byte in data[offset:offset + 16]))
        for key, value in values.items():
            lines += [f"PUBLIC {symbol}_{key}", f"defc {symbol}_{key} = {value}"]
        lines += [""]
    return "\n".join(lines)


def register_parser(subparsers):
    parser = subparsers.add_parser("emit", help="binary, optionally compressed externally, to C/ASM source")
    parser.add_argument("input", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--symbol", required=True)
    parser.add_argument("--language", choices=("c", "asm"), default="c")
    parser.add_argument("--metadata", type=Path)
    parser.add_argument("--compression", choices=("none", "zx0", "zx7"), default="none")
    parser.add_argument("--section", default="rodata_user")
    parser.add_argument("--origin", type=lambda value: int(value, 0))
    parser.set_defaults(handler=run)


def run(args):
    metadata = json.loads(args.metadata.read_text()) if args.metadata else None
    source = emit_source(args.input.read_bytes(), symbol=args.symbol, dialect=args.language,
                         metadata=metadata, compression=args.compression,
                         section=args.section, origin=args.origin)
    return ((args.output, source.encode("utf-8")),)
