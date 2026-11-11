#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

static const char hello[16] = "HELLO.TXT";
static const char missing[16] = "MISSING.TXT";
static char text[256];

int main(void) {
    bc_ers_device_info_t device;
    bc_ers_fat_search_result_t found;
    uint8_t entry[32];
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
    ZX_ASSERT(bc_ers_fat_get_path(text) == ZX_OK);
    ZX_ASSERT(memcmp(text, "E:/", sizeof("E:/")) == 0);
    zx_test_step_marker("root");

    status = bc_ers_fat_find_short_name(hello, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found && found.directory_entry == 0);
    if (status == ZX_OK && !found.not_found) {
        ZX_ASSERT(bc_ers_fat_get_long_name(text) == ZX_OK);
        ZX_ASSERT(memcmp(text, hello, sizeof("HELLO.TXT")) == 0);
        ZX_ASSERT(bc_ers_fat_read_directory_entry(found.directory_entry, entry) == ZX_OK);
        ZX_ASSERT(memcmp(entry, "HELLO   TXT", 11) == 0);
        ZX_ASSERT(entry[11] == 0x20);
        ZX_ASSERT(entry[28] == sizeof("BaseConf HDD fixture.\r\n") - 1);
        ZX_ASSERT((entry[29] | entry[30] | entry[31]) == 0);
    }
    zx_test_step_marker("find_hello");

    status = bc_ers_fat_find_short_name(missing, &found);
    ZX_ASSERT(status == ZX_OK && found.not_found);
    zx_test_step_marker("missing");
    zx_test_finish();
    return 0;
}
