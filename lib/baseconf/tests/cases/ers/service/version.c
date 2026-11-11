#include <baseconf.h>
#include <baseconf/ers.h>
#include <baseconf/rom.h>

#include "bc_case.h"

int main(void) {
    bc_ers_version_t version = {0, 0, 0, 0, 0};
    zx_status_t status;

    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    bc_ers_set_profile(BC_ERS_NONE);
    ZX_ASSERT(bc_ers_is_available() == 0);
    ZX_ASSERT(bc_ers_read_version(NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_ers_read_version(&version) == ZX_UNAVAILABLE);
    zx_test_step_marker("unavailable");

    /* The ERS runner keeps the real ROM in W0; code runs from W2 RAM. */
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_is_available() == 1);

    status = bc_ers_read_version(&version);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        /* BCDE is a packed, big-endian version; accept later firmware builds. */
        ZX_ASSERT(version.b > 0x00u || version.c > 0x00u || version.d > 0x61u ||
                  (version.d == 0x61u && version.e >= 0x01u));
        ZX_ASSERT((version.flags & 0x01u) != 0);
    }
    zx_test_step_marker("version");

    zx_test_finish();
    return 0;
}
