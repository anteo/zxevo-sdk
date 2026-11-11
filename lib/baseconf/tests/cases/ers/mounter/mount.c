#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

#define DRIVE 1u

static const char docs[16] = "DOCS";
static const char disk[16] = "DISK.TRD";
static bc_ers_mounted_image_t images[4];
static uint8_t sector[257];

static void check_mount(uint8_t expected) {
    uint8_t mounted = 0xff;
    uint8_t bits = 0xff;

    ZX_ASSERT(bc_ers_mounter_drive_has_mounted_image(DRIVE, &mounted) == ZX_OK);
    ZX_ASSERT(mounted == expected);
    ZX_ASSERT(bc_ers_mounter_get_virtual_drive_bits(&bits) == ZX_OK);
    ZX_ASSERT(((bits >> DRIVE) & 1u) == expected);
}

static void read_sector(uint8_t number) {
    memset(sector, 0xcc, sizeof(sector));
    ZX_ASSERT(bc_ers_mounter_read_write_mounted(DRIVE, 0, 1, number, sector) == ZX_OK);
    ZX_ASSERT(sector[256] == 0xcc);
}

static void check_pattern(uint8_t mask) {
    uint16_t i;

    for (i = 0; i < 256u; ++i) {
        if (sector[i] != (uint8_t)(i ^ mask)) break;
    }
    ZX_ASSERT(i == 256u);
}

int main(void) {
    bc_ers_device_info_t device;
    bc_ers_fat_search_result_t found;
    zx_status_t status;
    uint16_t i;

    if (bc_case_init() != ZX_OK) {
        zx_test_finish();
        return 0;
    }
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);
    status = bc_ers_device_find(&device);
    ZX_ASSERT(status == ZX_OK && device.found);
    if (status != ZX_OK || !device.found) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_ers_device_set_volume(0) == ZX_OK);
    ZX_ASSERT(bc_ers_fat_root_directory() == ZX_OK);
    status = bc_ers_fat_find_short_name(docs, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found);
    if (status != ZX_OK || found.not_found) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_ers_fat_enter_directory() == ZX_OK);
    status = bc_ers_fat_find_short_name(disk, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found);
    if (status != ZX_OK || found.not_found) {
        zx_test_finish();
        return 0;
    }

    check_mount(0);
    ZX_ASSERT(bc_ers_mounter_mount_file(DRIVE) == ZX_OK);
    check_mount(1);
    ZX_ASSERT(bc_ers_mounter_get_mounted_images(images) == ZX_OK);
    ZX_ASSERT(memcmp(images[DRIVE].bytes, "DISK    TRD", 11) == 0);
    zx_test_step_marker("mount");

    read_sector(2);
    check_pattern(0xa5);
    zx_test_step_marker("read_sector");

    for (i = 0; i < 256u; ++i) {
        sector[i] = (uint8_t)(i ^ 0x5au);
    }
    ZX_ASSERT(bc_ers_mounter_read_write_mounted(DRIVE, 1, 1, 2, sector) == ZX_OK);
    zx_test_step_marker("write_sector");

    ZX_ASSERT(bc_ers_mounter_unmount(DRIVE) == ZX_OK);
    check_mount(0);
    status = bc_ers_fat_find_short_name(disk, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found);
    if (status != ZX_OK || found.not_found) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_ers_mounter_mount_file(DRIVE) == ZX_OK);
    check_mount(1);
    read_sector(2);
    check_pattern(0x5a);
    /* Both TRD sectors share the same 512-byte HDD sector. */
    read_sector(1);
    for (i = 0; i < 256u; ++i) {
        if (sector[i] != 0) break;
    }
    ZX_ASSERT(i == 256u);
    zx_test_step_marker("remount_readback");

    ZX_ASSERT(bc_ers_mounter_unmount(DRIVE) == ZX_OK);
    check_mount(0);
    ZX_ASSERT(bc_ers_mounter_get_mounted_images(images) == ZX_OK);
    ZX_ASSERT(images[DRIVE].bytes[0] == 0);
    zx_test_step_marker("unmount");
    zx_test_finish();
    return 0;
}
