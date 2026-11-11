#include <baseconf.h>

#include "bc_case.h"

#define CMOS_DRIVES_INDEX 0xebu
#define STORAGE_FLAGS 0xc0u

static void check_assignment(uint8_t real, uint8_t virtual) {
    uint8_t setting = 0;
    uint8_t bits = 0;
    uint8_t expected = (uint8_t)(STORAGE_FLAGS | (real << 2) | virtual);

    ZX_ASSERT(bc_ers_cmos_read(CMOS_DRIVES_INDEX, &setting) == ZX_OK);
    ZX_ASSERT(setting == expected);
    ZX_ASSERT(bc_ers_mounter_get_virtual_drive_bits(&bits) == ZX_OK);
    ZX_ASSERT((bits & 0xf0u) == (0x10u << virtual));
}

int main(void) {
    uint8_t original;
    zx_status_t status;

    if (bc_case_init() != ZX_OK) {
        zx_test_finish();
        return 0;
    }
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);
    status = bc_ers_cmos_read(CMOS_DRIVES_INDEX, &original);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_finish();
        return 0;
    }

    /* Start with both assignments at A and SD/IDE master enabled. */
    ZX_ASSERT(bc_ers_cmos_write(CMOS_DRIVES_INDEX, STORAGE_FLAGS) == ZX_OK);
    ZX_ASSERT(bc_ers_mounter_set_real_drive(2) == ZX_OK);
    check_assignment(2, 0);
    zx_test_step_marker("real_drive");

    ZX_ASSERT(bc_ers_mounter_set_virtual_drive(1) == ZX_OK);
    check_assignment(2, 1);
    zx_test_step_marker("virtual_drive");

    ZX_ASSERT(bc_ers_mounter_set_virtual_and_real_drive(3) == ZX_OK);
    check_assignment(3, 3);
    zx_test_step_marker("both_drives");

    ZX_ASSERT(bc_ers_cmos_write(CMOS_DRIVES_INDEX, original) == ZX_OK);
    zx_test_finish();
    return 0;
}
