#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

static const char hello[16] = "HELLO.TXT";
static const char expected[] = "BaseConf HDD fixture.\r\n";
static uint8_t buffer[1024];

int main(void) {
    bc_ers_device_info_t device;
    bc_ers_fat_search_result_t found;
    bc_ers_fat_read_result_t result;
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
    status = bc_ers_fat_find_short_name(hello, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found);
    if (status != ZX_OK || found.not_found) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_ers_fat_open_file() == ZX_OK);
    zx_test_step_marker("open");

    /* The file fits in one sector. Asking for two should stop at EOF. */
    memset(buffer, 0xa5, sizeof(buffer));
    status = bc_ers_fat_read_file(2, buffer, &result);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(result.next_address == (uint16_t)(uintptr_t)(buffer + 512));
        ZX_ASSERT(result.carry == 1);
        ZX_ASSERT(memcmp(buffer, expected, sizeof(expected) - 1) == 0);
        ZX_ASSERT(buffer[512] == 0xa5);
    }
    zx_test_step_marker("read_eof");
    zx_test_finish();
    return 0;
}
