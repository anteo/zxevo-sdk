#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

static const char docs[16] = "DOCS";
static const char note[16] = "NOTE.BIN";
static const char hello[16] = "HELLO.TXT";
static char path[256];

int main(void) {
    bc_ers_device_info_t device;
    bc_ers_fat_search_result_t found;
    uint8_t entry[32];
    uint16_t position = 0;
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

    ZX_ASSERT(bc_ers_fat_position_files(BC_ERS_FAT_POSITION_FIRST, &position) == ZX_OK);
    ZX_ASSERT(position == 0);
    ZX_ASSERT(bc_ers_fat_position_files(BC_ERS_FAT_POSITION_SAVE, &position) == ZX_OK);
    position = 0x0100;
    ZX_ASSERT(bc_ers_fat_position_files(BC_ERS_FAT_POSITION_FORWARD, &position) == ZX_OK);
    ZX_ASSERT(position == 1);
    ZX_ASSERT(bc_ers_fat_position_files(BC_ERS_FAT_POSITION_RESTORE, &position) == ZX_OK);
    ZX_ASSERT(position == 0);
    zx_test_step_marker("position");

    status = bc_ers_fat_find_short_name(docs, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found && found.directory_entry == 2);
    if (status != ZX_OK || found.not_found) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_ers_fat_enter_directory() == ZX_OK);
    ZX_ASSERT(bc_ers_fat_get_path(path) == ZX_OK);
    ZX_ASSERT(memcmp(path, "E:/DOCS/", sizeof("E:/DOCS/")) == 0);
    status = bc_ers_fat_find_short_name(note, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found && found.directory_entry == 2);
    zx_test_step_marker("enter_docs");

    ZX_ASSERT(bc_ers_fat_read_directory_entry(1, entry) == ZX_OK);
    ZX_ASSERT(memcmp(entry, "..         ", 11) == 0 && entry[11] == 0x10);
    ZX_ASSERT(bc_ers_fat_enter_directory() == ZX_OK);
    ZX_ASSERT(bc_ers_fat_get_path(path) == ZX_OK);
    ZX_ASSERT(memcmp(path, "E:/", sizeof("E:/")) == 0);
    status = bc_ers_fat_find_short_name(hello, &found);
    ZX_ASSERT(status == ZX_OK && !found.not_found && found.directory_entry == 0);
    zx_test_step_marker("parent");
    zx_test_finish();
    return 0;
}
