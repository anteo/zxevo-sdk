#!/usr/bin/env python3
"""Convert image/audio assets or emit binary resources as C/ASM source.

Compression is a separate step using external binary compressors.
"""

import argparse
from pathlib import Path

if __package__:
    from . import audio, emit, image, pack, tiles
else:
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from tools.assets import audio, emit, image, pack, tiles

from tools.python.environment import ensure_environment


def register_commands(subparsers):
    for command in (image, audio, emit, pack, tiles):
        command.register_parser(subparsers)


def write_output(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    size = path.write_bytes(data)
    print(f"Created: {path.resolve()} ({size} bytes)")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    register_commands(parser.add_subparsers(dest="command", required=True))
    args = parser.parse_args()
    try:
        if args.command in ("image", "atlas"):
            ensure_environment(Path(__file__).with_name("requirements.txt"))
        for path, data in args.handler(args):
            write_output(path, data)
    except (OSError, ValueError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
