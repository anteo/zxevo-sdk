#!/usr/bin/env python3
"""Make a FAT32 image with a fragmented file and a nested directory."""

import struct
import sys
from pathlib import Path

SECTOR_SIZE = 512
PARTITION_START = 2048
RESERVED_SECTORS = 32
CLUSTERS = 65536
FAT_SECTORS = ((CLUSTERS + 2) * 4 + SECTOR_SIZE - 1) // SECTOR_SIZE
PARTITION_SECTORS = RESERVED_SECTORS + 2 * FAT_SECTORS + CLUSTERS


def write_sector(image, lba, data):
    image.seek(lba * SECTOR_SIZE)
    image.write(data)


def create_image(path):
    payload = bytes((37 * i + (i >> 3) + 0x23) & 0xFF for i in range(777))

    mbr = bytearray(SECTOR_SIZE)
    struct.pack_into("<B3sB3sII", mbr, 446,
                     0, b"\xfe\xff\xff", 0x0C, b"\xfe\xff\xff",
                     PARTITION_START, PARTITION_SECTORS)
    mbr[510:] = b"\x55\xaa"

    boot = bytearray(SECTOR_SIZE)
    boot[:11] = b"\xeb\x58\x90MSDOS5.0"
    struct.pack_into("<HBHBHHBHHHII", boot, 11,
                     SECTOR_SIZE, 1, RESERVED_SECTORS, 2, 0, 0,
                     0xF8, 0, 63, 255, PARTITION_START, PARTITION_SECTORS)
    struct.pack_into("<IHHIHH", boot, 36, FAT_SECTORS, 0, 0, 2, 1, 6)
    boot[64] = 0x80
    boot[66] = 0x29
    struct.pack_into("<I", boot, 67, 0x54534641)
    boot[71:90] = b"TS-FAT TESTFAT32   "
    boot[510:] = b"\x55\xaa"

    fsinfo = bytearray(SECTOR_SIZE)
    struct.pack_into("<I", fsinfo, 0, 0x41615252)
    struct.pack_into("<IIII", fsinfo, 484, 0x61417272, CLUSTERS - 5, 6, 0xAA550000)

    fat = bytearray(SECTOR_SIZE)
    eoc = 0x0FFFFFFF
    struct.pack_into("<4I", fat, 0, 0x0FFFFFF8, eoc, eoc, 9)
    struct.pack_into("<2I", fat, 4 * 4, eoc, eoc)
    struct.pack_into("<I", fat, 9 * 4, eoc)

    root = bytearray(SECTOR_SIZE)
    root[:12] = b"HELLO   BIN\x20"
    struct.pack_into("<HI", root, 26, 3, len(payload))
    root[32:44] = b"NEST       \x10"
    struct.pack_into("<H", root, 32 + 26, 4)

    directory = bytearray(SECTOR_SIZE)
    directory[:12] = b".          \x10"
    struct.pack_into("<H", directory, 26, 4)
    directory[32:44] = b"..         \x10"
    directory[64:76] = b"INNER   BIN\x20"
    struct.pack_into("<HI", directory, 64 + 26, 5, 512)

    fat_start = PARTITION_START + RESERVED_SECTORS
    data_start = fat_start + 2 * FAT_SECTORS
    with path.open("wb") as image:
        image.truncate((PARTITION_START + PARTITION_SECTORS) * SECTOR_SIZE)
        write_sector(image, 0, mbr)
        for offset in (0, 6):
            write_sector(image, PARTITION_START + offset, boot)
            write_sector(image, PARTITION_START + offset + 1, fsinfo)
        write_sector(image, fat_start, fat)
        write_sector(image, fat_start + FAT_SECTORS, fat)
        write_sector(image, data_start, root)
        write_sector(image, data_start + 1, payload[:SECTOR_SIZE])
        write_sector(image, data_start + 2, directory)
        write_sector(image, data_start + 3, payload[:SECTOR_SIZE])
        write_sector(image, data_start + 7, payload[SECTOR_SIZE:])


if __name__ == "__main__":
    create_image(Path(sys.argv[1]) / "ts-fat.img")
