#include <baseconf.h>
#include <baseconf/ers.h>
#include <baseconf/rom.h>

#include "bc_case.h"

int main(void) {
    bc_ers_device_info_t found;
    bc_ers_device_info_t current;
    uint8_t volume_table[256];
    uint8_t sd_availability = 0;
    zx_status_t status;

    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    /* The ERS runner keeps the real ROM in W0; code runs from W2 RAM. */
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);

    status = bc_ers_device_find(&found);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(found.found == 1);
    ZX_ASSERT(found.partition_count == 2);
    ZX_ASSERT(found.current_partition < found.partition_count);
    ZX_ASSERT(found.fat_type == 1 || found.fat_type == 2);
    zx_test_step_marker("find");

    status = bc_ers_device_get_volume_table(volume_table);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_finish();
        return 0;
    }
    /* Each 8-byte entry stores the ERS FAT type at offset +2. */
    ZX_ASSERT((volume_table[2] == 1 && volume_table[10] == 2) ||
              (volume_table[2] == 2 && volume_table[10] == 1));
    /* This ROM build assigns device 4 to Nemo master and 15 to ZC SD. */
    ZX_ASSERT(volume_table[0] == 4);
    ZX_ASSERT(volume_table[1] == 0);
    ZX_ASSERT(volume_table[8] == 15);
    ZX_ASSERT(volume_table[9] == 0);

    status = bc_ers_device_get_current_volume(&current);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(current.found == found.found);
        ZX_ASSERT(current.partition_count == found.partition_count);
        ZX_ASSERT(current.current_partition == found.current_partition);
        ZX_ASSERT(current.fat_type == found.fat_type);
    }
    zx_test_step_marker("volumes");

    status = bc_ers_device_check_sd(&sd_availability);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) ZX_ASSERT((sd_availability & 0x01u) != 0);
    zx_test_step_marker("sd");

    zx_test_finish();
    return 0;
}
