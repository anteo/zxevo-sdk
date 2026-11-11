#include <baseconf.h>
#include <baseconf/ers.h>
#include <baseconf/rom.h>

#include "bc_case.h"

int main(void) {
    bc_ers_device_info_t info;
    bc_ers_device_info_t current;
    uint8_t index;
    zx_status_t status;

    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);
    status = bc_ers_device_find(&info);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK || !info.found || info.partition_count < 2) {
        zx_test_finish();
        return 0;
    }

    for (index = 0; index < info.partition_count; ++index) {
        ZX_ASSERT(bc_ers_device_set_volume(index) == ZX_OK);
        status = bc_ers_device_get_current_volume(&current);
        ZX_ASSERT(status == ZX_OK);
        if (status != ZX_OK) {
            zx_test_finish();
            return 0;
        }
        ZX_ASSERT(current.found == 1);
        ZX_ASSERT(current.current_partition == index);
        ZX_ASSERT(current.partition_count == info.partition_count);
    }
    zx_test_step_marker("select");

    ZX_ASSERT(bc_ers_device_set_volume(info.partition_count) == ZX_INVALID_ARGUMENT);
    status = bc_ers_device_get_current_volume(&current);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(current.current_partition == info.partition_count - 1u);
    }
    zx_test_step_marker("reject_out_of_range");

    ZX_ASSERT(bc_ers_device_set_volume(info.current_partition) == ZX_OK);
    zx_test_finish();
    return 0;
}
