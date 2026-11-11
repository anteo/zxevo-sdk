#include <baseconf.h>
#include <baseconf/ers.h>
#include <baseconf/rom.h>

#include "bc_case.h"

#define CMOS_SETTINGS_COUNT 7u

static const uint8_t cmos_indices[CMOS_SETTINGS_COUNT] = {0xedu, 0xecu, 0xebu, 0xeau,
                                                          0xe9u, 0xe8u, 0xe7u};

static const uint8_t cmos_defaults[CMOS_SETTINGS_COUNT] = {0x04u, 0x82u, 0x00u, 0x00u,
                                                           0x00u, 0x00u, 0x00u};

int main(void) {
    uint8_t original[CMOS_SETTINGS_COUNT];
    uint8_t actual;
    uint8_t i;
    uint8_t snapshot_ok = 1;
    zx_status_t status;

    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    /* The ERS runner keeps the real ROM in W0; code runs from W2 RAM. */
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    status = bc_ers_cmos_init();
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_finish();
        return 0;
    }

    /* Preserve the complete ERS settings block before resetting it. */
    for (i = 0; i < CMOS_SETTINGS_COUNT; ++i) {
        status = bc_ers_cmos_read(cmos_indices[i], &original[i]);
        ZX_ASSERT(status == ZX_OK);
        if (status != ZX_OK) {
            snapshot_ok = 0;
            break;
        }
    }

    if (!snapshot_ok) {
        zx_test_finish();
        return 0;
    }

    status = bc_ers_cmos_reset_defaults();
    ZX_ASSERT(status == ZX_OK);
    for (i = 0; i < CMOS_SETTINGS_COUNT; ++i) {
        status = bc_ers_cmos_read(cmos_indices[i], &actual);
        ZX_ASSERT(status == ZX_OK);
        if (status == ZX_OK) ZX_ASSERT(actual == cmos_defaults[i]);
    }

    /* Restore every saved setting; each write also refreshes the ERS CRC. */
    for (i = 0; i < CMOS_SETTINGS_COUNT; ++i) {
        ZX_ASSERT(bc_ers_cmos_write(cmos_indices[i], original[i]) == ZX_OK);
    }
    for (i = 0; i < CMOS_SETTINGS_COUNT; ++i) {
        status = bc_ers_cmos_read(cmos_indices[i], &actual);
        ZX_ASSERT(status == ZX_OK);
        if (status == ZX_OK) ZX_ASSERT(actual == original[i]);
    }

    zx_test_step_marker("reset");
    zx_test_finish();
    return 0;
}
