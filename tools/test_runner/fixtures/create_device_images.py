#!/usr/bin/env python3
"""Create deterministic FAT images for the ERS storage tests."""

import math
import struct
import sys
from pathlib import Path

SECTOR_SIZE = 512
PARTITION_START = 2048


def mbr_partition(partition_type, start, sectors):
    sector = bytearray(SECTOR_SIZE)
    struct.pack_into("<B3sB3sII", sector, 446,
                     0, b"\xfe\xff\xff", partition_type, b"\xfe\xff\xff",
                     start, sectors)
    sector[510:512] = b"\x55\xaa"
    return sector


def fat16_image(path, total_sectors):
    partition_sectors = total_sectors - PARTITION_START
    sectors_per_cluster = 1
    reserved = 1
    fats = 2
    root_entries = 512
    root_sectors = root_entries * 32 // SECTOR_SIZE
    fat_sectors = 1
    while True:
        clusters = (partition_sectors - reserved - fats * fat_sectors - root_sectors) // sectors_per_cluster
        needed = math.ceil((clusters + 2) * 2 / SECTOR_SIZE)
        if needed == fat_sectors:
            break
        fat_sectors = needed
    if clusters < 4085 or clusters >= 65525:
        raise ValueError(f"FAT16 image has invalid cluster count: {clusters}")

    image = bytearray(total_sectors * SECTOR_SIZE)
    image[:SECTOR_SIZE] = mbr_partition(0x06, PARTITION_START, partition_sectors)

    boot = bytearray(SECTOR_SIZE)
    boot[0:3] = b"\xeb\x3c\x90"
    boot[3:11] = b"MSDOS5.0"
    struct.pack_into("<HBHBHHBHHHII", boot, 11,
                     SECTOR_SIZE, sectors_per_cluster, reserved, fats,
                     root_entries, partition_sectors if partition_sectors <= 0xffff else 0,
                     0xf8, fat_sectors, 63, 255, PARTITION_START,
                     0 if partition_sectors <= 0xffff else partition_sectors)
    boot[36] = 0x80
    boot[38] = 0x29
    struct.pack_into("<I", boot, 39, 0x42434631)
    boot[43:54] = b"BASECONF SD"
    boot[54:62] = b"FAT16   "
    boot[510:512] = b"\x55\xaa"
    image[PARTITION_START * SECTOR_SIZE:(PARTITION_START + 1) * SECTOR_SIZE] = boot

    fat_start = PARTITION_START + reserved
    fat = bytearray(fat_sectors * SECTOR_SIZE)
    struct.pack_into("<4H", fat, 0, 0xfff8, 0xffff, 0xffff, 0xffff)
    for copy_index in range(fats):
        offset = (fat_start + copy_index * fat_sectors) * SECTOR_SIZE
        image[offset:offset + len(fat)] = fat

    root_start = PARTITION_START + reserved + fats * fat_sectors
    root = bytearray(root_sectors * SECTOR_SIZE)
    write_directory_entry(root, 0, b"HELLO   TXT", 2, len(b"BaseConf SD fixture.\r\n"))
    write_directory_entry(root, 32, b"DEVICE  TXT", 3, len(b"DEVICE=SD\r\n"))
    offset = root_start * SECTOR_SIZE
    image[offset:offset + len(root)] = root

    data_start = root_start + root_sectors
    write_cluster(image, data_start, sectors_per_cluster, 2, b"BaseConf SD fixture.\r\n")
    write_cluster(image, data_start, sectors_per_cluster, 3, b"DEVICE=SD\r\n")
    path.write_bytes(image)


def fat32_image(path, total_sectors, mount_list=b""):
    partition_sectors = total_sectors - PARTITION_START
    sectors_per_cluster = 1
    reserved = 32
    fats = 2
    fat_sectors = 1
    while True:
        clusters = partition_sectors - reserved - fats * fat_sectors
        needed = math.ceil((clusters + 2) * 4 / SECTOR_SIZE)
        if needed == fat_sectors:
            break
        fat_sectors = needed
    if clusters < 65525:
        raise ValueError(f"FAT32 image has invalid cluster count: {clusters}")

    trd = trd_image()
    trd_start = 7
    trd_end = trd_start + len(trd) // SECTOR_SIZE
    tape = tap_block(b"TAPE 1") + tap_block(b"TAPE TWO!")
    tape_cluster = trd_end
    mount_cluster = tape_cluster + 1
    next_cluster = mount_cluster + bool(mount_list)
    image = bytearray(total_sectors * SECTOR_SIZE)
    image[:SECTOR_SIZE] = mbr_partition(0x0c, PARTITION_START, partition_sectors)

    boot = bytearray(SECTOR_SIZE)
    boot[0:3] = b"\xeb\x58\x90"
    boot[3:11] = b"MSDOS5.0"
    struct.pack_into("<HBHBHHBHHHII", boot, 11,
                     SECTOR_SIZE, sectors_per_cluster, reserved, fats,
                     0, 0, 0xf8, 0, 63, 255, PARTITION_START, partition_sectors)
    struct.pack_into("<IHHIHH", boot, 36,
                     fat_sectors, 0, 0, 2, 1, 6)
    boot[64] = 0x80
    boot[66] = 0x29
    struct.pack_into("<I", boot, 67, 0x42434632)
    boot[71:82] = b"BASECONF HD"
    boot[82:90] = b"FAT32   "
    boot[510:512] = b"\x55\xaa"
    boot_offset = PARTITION_START * SECTOR_SIZE
    image[boot_offset:boot_offset + SECTOR_SIZE] = boot
    backup_offset = (PARTITION_START + 6) * SECTOR_SIZE
    image[backup_offset:backup_offset + SECTOR_SIZE] = boot

    fsinfo = bytearray(SECTOR_SIZE)
    struct.pack_into("<I", fsinfo, 0, 0x41615252)
    struct.pack_into("<I", fsinfo, 484, 0x61417272)
    struct.pack_into("<II", fsinfo, 488, clusters - (next_cluster - 2), next_cluster)
    struct.pack_into("<I", fsinfo, 508, 0xaa550000)
    fsinfo_offset = (PARTITION_START + 1) * SECTOR_SIZE
    image[fsinfo_offset:fsinfo_offset + SECTOR_SIZE] = fsinfo
    backup_info_offset = (PARTITION_START + 7) * SECTOR_SIZE
    image[backup_info_offset:backup_info_offset + SECTOR_SIZE] = fsinfo

    fat = bytearray(fat_sectors * SECTOR_SIZE)
    struct.pack_into("<7I", fat, 0, 0x0ffffff8, *([0x0fffffff] * 6))
    for cluster in range(trd_start, trd_end - 1):
        struct.pack_into("<I", fat, cluster * 4, cluster + 1)
    struct.pack_into("<I", fat, (trd_end - 1) * 4, 0x0fffffff)
    struct.pack_into("<I", fat, tape_cluster * 4, 0x0fffffff)
    if mount_list:
        struct.pack_into("<I", fat, mount_cluster * 4, 0x0fffffff)
    fat_start = PARTITION_START + reserved
    for copy_index in range(fats):
        offset = (fat_start + copy_index * fat_sectors) * SECTOR_SIZE
        image[offset:offset + len(fat)] = fat

    data_start = PARTITION_START + reserved + fats * fat_sectors
    root = bytearray(SECTOR_SIZE)
    write_directory_entry(root, 0, b"HELLO   TXT", 3, len(b"BaseConf HDD fixture.\r\n"))
    write_directory_entry(root, 32, b"DEVICE  TXT", 4, len(b"DEVICE=HDD\r\n"))
    write_directory_entry(root, 64, b"DOCS       ", 5, 0, attributes=0x10)
    if mount_list:
        write_directory_entry(root, 96, b"IMAGE   MNT", mount_cluster, len(mount_list))
        write_cluster(image, data_start, sectors_per_cluster, mount_cluster, mount_list)
    offset = data_start * SECTOR_SIZE
    image[offset:offset + SECTOR_SIZE] = root
    write_cluster(image, data_start, sectors_per_cluster, 3, b"BaseConf HDD fixture.\r\n")
    write_cluster(image, data_start, sectors_per_cluster, 4, b"DEVICE=HDD\r\n")
    docs = bytearray(SECTOR_SIZE)
    note = b"BaseConf subdirectory.\r\n"
    write_directory_entry(docs, 0, b".          ", 5, 0, attributes=0x10)
    write_directory_entry(docs, 32, b"..         ", 0, 0, attributes=0x10)
    write_directory_entry(docs, 64, b"NOTE    BIN", 6, len(note))
    write_directory_entry(docs, 96, b"DISK    TRD", trd_start, len(trd))
    write_directory_entry(docs, 128, b"LOAD    TAP", tape_cluster, len(tape))
    write_cluster(image, data_start, sectors_per_cluster, 5, docs)
    write_cluster(image, data_start, sectors_per_cluster, 6, note)
    write_cluster(image, data_start, sectors_per_cluster, trd_start, trd)
    write_cluster(image, data_start, sectors_per_cluster, tape_cluster, tape)
    path.write_bytes(image)


def tap_block(payload):
    flag = 0xff
    checksum = flag
    for byte in payload:
        checksum ^= byte
    return struct.pack("<HB", len(payload) + 2, flag) + payload + bytes((checksum,))


def trd_image():
    image = bytearray(160 * 16 * 256)
    # One two-sector CODE file starting at track 1, sector 1.
    struct.pack_into("<9sHHBBB", image, 0, b"SECTOR  C", 0x8000, 512, 2, 0, 1)
    # TR-DOS disk information at track 0, sector 9.
    info = 8 * 256
    struct.pack_into("<BBBBHB", image, info + 0xe1, 2, 1, 0x16, 1, 2542, 0x10)
    image[info + 0xf5:info + 0xfd] = b"BASECONF"
    # The second TRD sector shares an HDD sector with the first one.
    image[17 * 256:18 * 256] = bytes(i ^ 0xa5 for i in range(256))
    return image


def write_directory_entry(directory, offset, short_name, cluster, size, attributes=0x20):
    entry = bytearray(32)
    entry[:11] = short_name
    entry[11] = attributes
    struct.pack_into("<H", entry, 26, cluster & 0xffff)
    struct.pack_into("<I", entry, 28, size)
    directory[offset:offset + 32] = entry


def write_cluster(image, data_start, sectors_per_cluster, cluster, contents):
    sector = data_start + (cluster - 2) * sectors_per_cluster
    offset = sector * SECTOR_SIZE
    image[offset:offset + len(contents)] = contents


def main():
    output = Path(sys.argv[1])
    output.mkdir(parents=True, exist_ok=True)
    fat16_image(output / "sd.img", 16 * 1024 * 1024 // SECTOR_SIZE)
    fat32_image(output / "hdd.img", 64 * 1024 * 1024 // SECTOR_SIZE)


if __name__ == "__main__":
    main()
