#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

#define CMOS_AUTOMOUNT_INDEX 0xecu
#define CMOS_AUTOMOUNT_ENABLE 0x20u
#define DRIVE_C 2u
#define DRIVE_D 3u

static bc_ers_mounted_image_t images[4];

int main(void) {
    bc_ers_device_info_t device;
    uint8_t original;
    uint8_t bits = 0;
    zx_status_t status;

    if (bc_case_init() != ZX_OK) {
        zx_test_finish();
        return 0;
    }
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);
    status = bc_ers_device_find(&device);
    ZX_ASSERT(status == ZX_OK && device.found && device.partition_count == 1);
    if (status != ZX_OK || !device.found || device.partition_count != 1) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_ers_device_set_volume(0) == ZX_OK);
    status = bc_ers_cmos_read(CMOS_AUTOMOUNT_INDEX, &original);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_finish();
        return 0;
    }

    /* Start with empty slots even if the firmware read IMAGE.MNT at boot. */
    ZX_ASSERT(bc_ers_mounter_unmount(DRIVE_C) == ZX_OK);
    ZX_ASSERT(bc_ers_mounter_unmount(DRIVE_D) == ZX_OK);
    ZX_ASSERT(bc_ers_mounter_get_virtual_drive_bits(&bits) == ZX_OK);
    ZX_ASSERT((bits & 0x0fu) == 0);

    ZX_ASSERT(bc_ers_cmos_write(CMOS_AUTOMOUNT_INDEX, original | CMOS_AUTOMOUNT_ENABLE) == ZX_OK);
    ZX_ASSERT(bc_ers_mounter_find_mounted_files() == ZX_OK);
    ZX_ASSERT(bc_ers_cmos_write(CMOS_AUTOMOUNT_INDEX, original) == ZX_OK);
    ZX_ASSERT(bc_ers_mounter_get_virtual_drive_bits(&bits) == ZX_OK);
    ZX_ASSERT((bits & 0x0fu) == (1u << DRIVE_C));
    ZX_ASSERT(bc_ers_mounter_get_mounted_images(images) == ZX_OK);
    ZX_ASSERT(memcmp(images[DRIVE_C].bytes, "DISK    TRD", 11) == 0);
    ZX_ASSERT(images[DRIVE_D].bytes[0] == 0);
    zx_test_step_marker("automount");

    ZX_ASSERT(bc_ers_mounter_unmount(DRIVE_C) == ZX_OK);
    zx_test_finish();
    return 0;
}
