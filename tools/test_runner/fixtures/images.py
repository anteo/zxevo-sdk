"""Create deterministic storage fixtures declared by test cases."""

import struct
from pathlib import Path

from ..support import FrameworkError

SECTOR_SIZE = 512
PARTITION_START = 2048
FAT_COPIES = 2
FAT32_RESERVED_SECTORS = 32


def prepare_images(directory, config):
    if not isinstance(config, dict):
        raise FrameworkError("emulator_images must be a table")
    images = {}
    filenames = set()
    for device, settings in config.items():
        if device not in {"mmc", "ide", "trd"}:
            raise FrameworkError(f"unknown emulator_images device: {device!r}")
        if not isinstance(settings, dict):
            raise FrameworkError(f"emulator_images.{device} must be a table")
        options = settings.copy()
        fixture = options.pop("fixture", None)
        filename = options.pop("filename", None)
        if not isinstance(fixture, str) or fixture not in FIXTURE_WRITERS:
            raise FrameworkError(f"emulator_images.{device}: unknown fixture {fixture!r}")
        if (not isinstance(filename, str) or filename in {"", ".", ".."}
                or Path(filename).name != filename or "\\" in filename):
            raise FrameworkError(f"emulator_images.{device}: filename must be a single file name")
        if filename.casefold() in filenames:
            raise FrameworkError(f"emulator_images.{device}: duplicate filename {filename!r}")
        filenames.add(filename.casefold())
        path = directory / filename
        try:
            directory.mkdir(parents=True, exist_ok=True)
            FIXTURE_WRITERS[fixture](path, **options)
        except (OSError, TypeError, ValueError) as error:
            raise FrameworkError(f"emulator_images.{device}: {error}") from error
        images[device] = path
    return images


def mbr_partition(partition_type, start, sectors):
    sector = bytearray(SECTOR_SIZE)
    struct.pack_into("<B3sB3sII", sector, 446,
                     0, b"\xfe\xff\xff", partition_type, b"\xfe\xff\xff",
                     start, sectors)
    sector[510:512] = b"\x55\xaa"
    return sector


def fat_geometry(size_sectors, reserved, root_sectors, entry_bytes):
    if type(size_sectors) is not int or not PARTITION_START < size_sectors <= 0xffffffff:
        raise ValueError("size_sectors must be an integer with room for the partition")
    partition_sectors = size_sectors - PARTITION_START
    # Each cluster occupies one sector and needs one entry in each FAT copy.
    available = partition_sectors - reserved - root_sectors
    numerator = (available + 2) * entry_bytes
    denominator = SECTOR_SIZE + FAT_COPIES * entry_bytes
    fat_sectors = (numerator + denominator - 1) // denominator
    clusters = available - FAT_COPIES * fat_sectors
    return partition_sectors, fat_sectors, clusters


def fat16_image(path, *, size_sectors):
    sectors_per_cluster = 1
    reserved = 1
    root_entries = 512
    root_sectors = root_entries * 32 // SECTOR_SIZE
    partition_sectors, fat_sectors, clusters = fat_geometry(size_sectors, reserved, root_sectors, 2)
    if clusters < 4085 or clusters >= 65525:
        raise ValueError(f"FAT16 image has invalid cluster count: {clusters}")

    image = bytearray(size_sectors * SECTOR_SIZE)
    image[:SECTOR_SIZE] = mbr_partition(0x06, PARTITION_START, partition_sectors)

    boot = bytearray(SECTOR_SIZE)
    boot[0:3] = b"\xeb\x3c\x90"
    boot[3:11] = b"MSDOS5.0"
    struct.pack_into("<HBHBHHBHHHII", boot, 11,
                     SECTOR_SIZE, sectors_per_cluster, reserved, FAT_COPIES,
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
    for copy_index in range(FAT_COPIES):
        offset = (fat_start + copy_index * fat_sectors) * SECTOR_SIZE
        image[offset:offset + len(fat)] = fat

    root_start = PARTITION_START + reserved + FAT_COPIES * fat_sectors
    root = bytearray(root_sectors * SECTOR_SIZE)
    write_directory_entry(root, 0, b"HELLO   TXT", 2, len(b"BaseConf SD fixture.\r\n"))
    write_directory_entry(root, 32, b"DEVICE  TXT", 3, len(b"DEVICE=SD\r\n"))
    offset = root_start * SECTOR_SIZE
    image[offset:offset + len(root)] = root

    data_start = root_start + root_sectors
    write_cluster(image, data_start, sectors_per_cluster, 2, b"BaseConf SD fixture.\r\n")
    write_cluster(image, data_start, sectors_per_cluster, 3, b"DEVICE=SD\r\n")
    path.write_bytes(image)


def fat32_geometry(size_sectors):
    partition_sectors, fat_sectors, clusters = fat_geometry(size_sectors, FAT32_RESERVED_SECTORS, 0, 4)
    if clusters < 65525:
        raise ValueError(f"FAT32 image has invalid cluster count: {clusters}")
    return partition_sectors, fat_sectors, clusters


def fat32_boot_sector(partition_sectors, fat_sectors, serial, label):
    boot = bytearray(SECTOR_SIZE)
    boot[:11] = b"\xeb\x58\x90MSDOS5.0"
    struct.pack_into("<HBHBHHBHHHII", boot, 11,
                     SECTOR_SIZE, 1, FAT32_RESERVED_SECTORS, FAT_COPIES,
                     0, 0, 0xf8, 0, 63, 255, PARTITION_START, partition_sectors)
    struct.pack_into("<IHHIHH", boot, 36,
                     fat_sectors, 0, 0, 2, 1, 6)
    boot[64] = 0x80
    boot[66] = 0x29
    struct.pack_into("<I", boot, 67, serial)
    boot[71:82] = label
    boot[82:90] = b"FAT32   "
    boot[510:512] = b"\x55\xaa"
    return boot


def fat32_fsinfo(free_clusters, next_cluster, *, signature_offset=508):
    fsinfo = bytearray(SECTOR_SIZE)
    struct.pack_into("<I", fsinfo, 0, 0x41615252)
    struct.pack_into("<I", fsinfo, 484, 0x61417272)
    struct.pack_into("<II", fsinfo, 488, free_clusters, next_cluster)
    struct.pack_into("<I", fsinfo, signature_offset, 0xaa550000)
    return fsinfo


def fat32_image(path, *, size_sectors, mount_list=()):
    partition_sectors, fat_sectors, clusters = fat32_geometry(size_sectors)
    sectors_per_cluster = 1
    if not isinstance(mount_list, (list, tuple)) or any(not isinstance(line, str) for line in mount_list):
        raise ValueError("mount_list must be an array of strings")
    mount_data = "".join(line + "\r\n" for line in mount_list).encode("ascii")
    if len(mount_data) > SECTOR_SIZE:
        raise ValueError("IMAGE.MNT must fit in one cluster")

    trd = trd_image()
    trd_start = 7
    trd_end = trd_start + len(trd) // SECTOR_SIZE
    tape = tap_block(b"TAPE 1") + tap_block(b"TAPE TWO!")
    tape_cluster = trd_end
    mount_cluster = tape_cluster + 1
    next_cluster = mount_cluster + bool(mount_data)
    image = bytearray(size_sectors * SECTOR_SIZE)
    image[:SECTOR_SIZE] = mbr_partition(0x0c, PARTITION_START, partition_sectors)
    boot = fat32_boot_sector(partition_sectors, fat_sectors, 0x42434632, b"BASECONF HD")
    fsinfo = fat32_fsinfo(clusters - (next_cluster - 2), next_cluster)
    for offset in (0, 6):
        boot_offset = (PARTITION_START + offset) * SECTOR_SIZE
        image[boot_offset:boot_offset + SECTOR_SIZE] = boot
        fsinfo_offset = boot_offset + SECTOR_SIZE
        image[fsinfo_offset:fsinfo_offset + SECTOR_SIZE] = fsinfo

    fat = bytearray(fat_sectors * SECTOR_SIZE)
    struct.pack_into("<7I", fat, 0, 0x0ffffff8, *([0x0fffffff] * 6))
    for cluster in range(trd_start, trd_end - 1):
        struct.pack_into("<I", fat, cluster * 4, cluster + 1)
    struct.pack_into("<I", fat, (trd_end - 1) * 4, 0x0fffffff)
    struct.pack_into("<I", fat, tape_cluster * 4, 0x0fffffff)
    if mount_data:
        struct.pack_into("<I", fat, mount_cluster * 4, 0x0fffffff)
    fat_start = PARTITION_START + FAT32_RESERVED_SECTORS
    for copy_index in range(FAT_COPIES):
        offset = (fat_start + copy_index * fat_sectors) * SECTOR_SIZE
        image[offset:offset + len(fat)] = fat

    data_start = fat_start + FAT_COPIES * fat_sectors
    root = bytearray(SECTOR_SIZE)
    write_directory_entry(root, 0, b"HELLO   TXT", 3, len(b"BaseConf HDD fixture.\r\n"))
    write_directory_entry(root, 32, b"DEVICE  TXT", 4, len(b"DEVICE=HDD\r\n"))
    write_directory_entry(root, 64, b"DOCS       ", 5, 0, attributes=0x10)
    if mount_data:
        write_directory_entry(root, 96, b"IMAGE   MNT", mount_cluster, len(mount_data))
        write_cluster(image, data_start, sectors_per_cluster, mount_cluster, mount_data)
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


def write_sector(image, lba, data):
    image.seek(lba * SECTOR_SIZE)
    image.write(data)


def ts_fat_image(path, *, size_sectors):
    """Write a fragmented root file and a file in a nested directory for TS-FAT."""
    partition_sectors, fat_sectors, clusters = fat32_geometry(size_sectors)
    payload = bytes((37 * i + (i >> 3) + 0x23) & 0xff for i in range(777))
    boot = fat32_boot_sector(partition_sectors, fat_sectors, 0x54534641, b"TS-FAT TEST")
    # Preserve the signature offset in the original TS-FAT fixture.
    fsinfo = fat32_fsinfo(clusters - 5, 6, signature_offset=496)

    fat = bytearray(SECTOR_SIZE)
    eoc = 0x0fffffff
    struct.pack_into("<4I", fat, 0, 0x0ffffff8, eoc, eoc, 9)
    struct.pack_into("<2I", fat, 4 * 4, eoc, eoc)
    struct.pack_into("<I", fat, 9 * 4, eoc)

    root = bytearray(SECTOR_SIZE)
    write_directory_entry(root, 0, b"HELLO   BIN", 3, len(payload))
    write_directory_entry(root, 32, b"NEST       ", 4, 0, attributes=0x10)

    directory = bytearray(SECTOR_SIZE)
    write_directory_entry(directory, 0, b".          ", 4, 0, attributes=0x10)
    write_directory_entry(directory, 32, b"..         ", 0, 0, attributes=0x10)
    write_directory_entry(directory, 64, b"INNER   BIN", 5, SECTOR_SIZE)

    fat_start = PARTITION_START + FAT32_RESERVED_SECTORS
    data_start = fat_start + FAT_COPIES * fat_sectors
    with path.open("wb") as image:
        image.truncate(size_sectors * SECTOR_SIZE)
        write_sector(image, 0, mbr_partition(0x0c, PARTITION_START, partition_sectors))
        for offset in (0, 6):
            write_sector(image, PARTITION_START + offset, boot)
            write_sector(image, PARTITION_START + offset + 1, fsinfo)
        for copy_index in range(FAT_COPIES):
            write_sector(image, fat_start + copy_index * fat_sectors, fat)
        write_sector(image, data_start, root)
        write_sector(image, data_start + 1, payload[:SECTOR_SIZE])
        write_sector(image, data_start + 2, directory)
        write_sector(image, data_start + 3, payload[:SECTOR_SIZE])
        write_sector(image, data_start + 7, payload[SECTOR_SIZE:])


def write_trd_image(path):
    path.write_bytes(trd_image())


FIXTURE_WRITERS = {
    "ers-fat16": fat16_image,
    "ers-fat32": fat32_image,
    "ts-fat32": ts_fat_image,
    "trd": write_trd_image,
}
