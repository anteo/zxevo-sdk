#!/usr/bin/env python3
"""Generate target-side C constants from lib/test_support/protocol.json."""
import json
import os
import sys


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: generate_header.py SPEC OUTPUT")
    with open(sys.argv[1], "r", encoding="utf-8") as stream:
        spec = json.load(stream)
    magic = spec["magic"].encode("ascii")
    if len(magic) != 4:
        raise SystemExit("ZXHost magic must be exactly four ASCII bytes")
    lines = [
        "#ifndef ZX_HOST_CONFIG_H",
        "#define ZX_HOST_CONFIG_H",
        "",
        "#define ZX_HOST_PROTOCOL_VERSION %du" % spec["version"],
        "#define ZX_HOST_HEADER_ADDRESS 0x%04Xu" % spec["header_address"],
        "#define ZX_HOST_HEADER_SIZE %du" % spec["header_size"],
        "#define ZX_HOST_LOG_ADDRESS 0x%04Xu" % spec["log_address"],
        "#define ZX_HOST_LOG_SIZE 0x%04Xu" % spec["log_size"],
    ]
    for index, byte in enumerate(magic):
        lines.append("#define ZX_HOST_MAGIC_%d 0x%02Xu" % (index, byte))
    for name, offset in spec["fields"].items():
        lines.append("#define ZX_HOST_FIELD_%s %du" % (name.upper(), offset))
    for name, value in spec["states"].items():
        lines.append("#define ZX_HOST_STATE_%s %du" % (name.upper(), value))
    lines.extend(["", "#endif", ""])
    os.makedirs(os.path.dirname(os.path.abspath(sys.argv[2])), exist_ok=True)
    with open(sys.argv[2], "w", encoding="ascii") as stream:
        stream.write("\n".join(lines))


if __name__ == "__main__":
    main()
