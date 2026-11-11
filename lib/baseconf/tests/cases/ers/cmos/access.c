#include <baseconf.h>
#include <baseconf/ers.h>
#include <baseconf/rom.h>

#include "bc_case.h"

/* ERS CMOS BYTE_02; avoid writing an RTC control register. */
#define CMOS_TEST_INDEX 0xe9u

int main(void) {
    uint8_t original = 0;
    uint8_t expected;
    uint8_t actual = 0;
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

    status = bc_ers_cmos_read(CMOS_TEST_INDEX, &original);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_finish();
        return 0;
    }

    expected = (uint8_t)(original ^ 0x5au);
    ZX_ASSERT(bc_ers_cmos_write(CMOS_TEST_INDEX, expected) == ZX_OK);

    status = bc_ers_cmos_read(CMOS_TEST_INDEX, &actual);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) ZX_ASSERT(actual == expected);

    /* Restore the original ERS setting even when write/readback failed. */
    ZX_ASSERT(bc_ers_cmos_write(CMOS_TEST_INDEX, original) == ZX_OK);
    status = bc_ers_cmos_read(CMOS_TEST_INDEX, &actual);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) ZX_ASSERT(actual == original);

    zx_test_step_marker("access");
    zx_test_finish();
    return 0;
}
