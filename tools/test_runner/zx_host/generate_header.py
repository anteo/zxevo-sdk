#!/usr/bin/env python3
"""Generate target-side constants from lib/test_support/protocol.json."""
import argparse
import json
from pathlib import Path


def generate_header(spec, output, output_format):
    magic = spec["magic"].encode("ascii")
    if len(magic) != 4:
        raise ValueError("ZXHost magic must be exactly four ASCII bytes")
    values = {
        "PROTOCOL_VERSION": str(spec["version"]),
        "HEADER_ADDRESS": f"0x{spec['header_address']:04X}",
        "HEADER_SIZE": str(spec["header_size"]),
        "LOG_ADDRESS": f"0x{spec['log_address']:04X}",
        "LOG_SIZE": f"0x{spec['log_size']:04X}",
    }
    for index, byte in enumerate(magic):
        values[f"MAGIC_{index}"] = f"0x{byte:02X}"
    for name, offset in spec["fields"].items():
        values[f"FIELD_{name.upper()}"] = str(offset)
    for name, value in spec["states"].items():
        values[f"STATE_{name.upper()}"] = str(value)

    if output_format == "sjasmplus":
        lines = [f"ZX_HOST_{name} equ {value}" for name, value in values.items()]
    else:
        lines = ["#ifndef ZX_HOST_CONFIG_H", "#define ZX_HOST_CONFIG_H", ""]
        lines.extend(f"#define ZX_HOST_{name} {value}u" for name, value in values.items())
        lines.extend(["", "#endif"])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", encoding="ascii")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--format", choices=("c", "sjasmplus"), default="c")
    args = parser.parse_args()
    spec = json.loads(args.spec.read_text(encoding="utf-8"))
    try:
        generate_header(spec, args.output, args.format)
    except ValueError as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
