#!/usr/bin/env python3
"""Create the shared TR-DOS fixture as a standalone disk image."""

import sys
from pathlib import Path

from create_device_images import trd_image


if __name__ == "__main__":
    (Path(sys.argv[1]) / "disk.trd").write_bytes(trd_image())
