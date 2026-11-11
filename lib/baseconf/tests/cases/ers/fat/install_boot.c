#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

#define FAT_VARIABLES_SIZE 256u

static const char hello[16] = "HELLO.TXT";
static const uint8_t loader_entry[] = {0xf3, 0x3a, 0xff, 0x42};
static uint8_t variables[FAT_VARIABLES_SIZE + 1];

int main(void) {
    volatile uint8_t *const loader = (volatile uint8_t *)0x4300u;
    bc_ers_device_info_t device;
    bc_ers_fat_search_result_t found;
    zx_status_t status;
    uint8_t i;

    if (bc_case_init() != ZX_OK) goto finish;
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);
    status = bc_ers_device_find(&device);
    ZX_ASSERT(status == ZX_OK && device.found && device.fat_type == 2);
    if (status != ZX_OK || !device.found || device.fat_type != 2) goto finish;

    ZX_ASSERT(bc_ers_device_set_volume(0) == ZX_OK);
    ZX_ASSERT(bc_ers_fat_root_directory() == ZX_OK);
    status = bc_ers_fat_find_short_name(hello, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found);
    if (status != ZX_OK || found.not_found) goto finish;
    ZX_ASSERT(bc_ers_fat_open_file() == ZX_OK);

    memset(variables, 0xcc, sizeof(variables));
    for (i = 0; i < sizeof(loader_entry); ++i) loader[i] = 0;
    ZX_ASSERT(bc_ers_install_fat_boot_variables(variables) == ZX_OK);
    /* The bundled loader starts with DI and LD A,($42FF). */
    for (i = 0; i < sizeof(loader_entry); ++i) ZX_ASSERT(loader[i] == loader_entry[i]);

    /* FAT type, number of FATs, sectors per cluster and root cluster. */
    ZX_ASSERT(memcmp(variables, "\x02\x02\x01\x02\0\0\0", 7) == 0);
    /* Partition start LBA 2048 and the directory record of the open file. */
    ZX_ASSERT(memcmp(variables + 17, "\0\x08\0\0", 4) == 0);
    ZX_ASSERT(memcmp(variables + 62, "HELLO   TXT", 11) == 0);
    ZX_ASSERT(variables[FAT_VARIABLES_SIZE] == 0xcc);
    zx_test_step_marker("install_boot");

finish:
    zx_test_finish();
    return 0;
}
