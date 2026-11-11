#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

static const char docs[16] = "DOCS";
static const char disk[16] = "DISK.TRD";
static uint8_t expected_entry[32];
static uint8_t loaded_entry[33];

int main(void) {
    bc_ers_device_info_t device;
    bc_ers_fat_search_result_t found;
    zx_status_t status;

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
    ZX_ASSERT(bc_ers_fat_read_directory_entry(found.directory_entry, expected_entry) == ZX_OK);
    ZX_ASSERT(memcmp(expected_entry, "DISK    TRD", 11) == 0);

    ZX_ASSERT(bc_ers_mounter_load_current_image() == ZX_OK);
    memset(loaded_entry, 0xcc, sizeof(loaded_entry));
    ZX_ASSERT(bc_ers_mounter_get_loaded_file_entry(loaded_entry) == ZX_OK);
    ZX_ASSERT(memcmp(loaded_entry, expected_entry, sizeof(expected_entry)) == 0);
    ZX_ASSERT(loaded_entry[32] == 0xcc);
    zx_test_step_marker("load_trd");
    zx_test_finish();
    return 0;
}
