#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

#define CMOS_TAPE_INDEX 0xedu
#define CMOS_TAPE_ENABLE 0x40u
#define BASIC_DESTINATION 0x5e00u

static const char docs[16] = "DOCS";
static const char tape[16] = "LOAD.TAP";
static const char first_block[] = "TAPE 1";
static const char second_block[] = "TAPE TWO!";

static uint8_t find_file(const char *name) {
    bc_ers_fat_search_result_t found;
    zx_status_t status = bc_ers_fat_find_short_name(name, &found);

    ZX_ASSERT(status == ZX_OK && !found.not_found);
    return status == ZX_OK && !found.not_found;
}

static void check_block(const char *expected, uint16_t length) {
    /* The tape hook loads $4000–$7FFF into standard ZX RAM page 5. */
    uint8_t *const loaded = (uint8_t *)(BASIC_DESTINATION + 0x8000u);
    bc_window_config_t config = {BC_RAM, 5, 0, 0};
    bc_window_lease_t lease;
    bc_ers_tape_result_t result;
    zx_status_t status = bc_window_acquire(ZX_WINDOW_3, config, &lease);

    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    memset(loaded, 0xcc, length + 1);
    status = bc_ers_tape_load((void *)BASIC_DESTINATION, length, &result);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(result.receiver == BASIC_DESTINATION + length);
        ZX_ASSERT(result.remaining == 0);
        ZX_ASSERT((result.flags & 1u) != 0);
    }
    ZX_ASSERT(memcmp(loaded, expected, length) == 0);
    ZX_ASSERT(loaded[length] == 0xcc);
    ZX_ASSERT(bc_window_release(&lease) == ZX_OK);
}

int main(void) {
    bc_ers_device_info_t device;
    zx_status_t status;
    uint8_t original;

    if (bc_case_init() != ZX_OK) goto finish;
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);
    status = bc_ers_device_find(&device);
    ZX_ASSERT(status == ZX_OK && device.found);
    if (status != ZX_OK || !device.found) goto finish;

    ZX_ASSERT(bc_ers_device_set_volume(0) == ZX_OK);
    ZX_ASSERT(bc_ers_fat_root_directory() == ZX_OK);
    if (!find_file(docs)) goto finish;
    ZX_ASSERT(bc_ers_fat_enter_directory() == ZX_OK);
    if (!find_file(tape)) goto finish;
    ZX_ASSERT(bc_ers_mounter_load_current_image() == ZX_OK);

    status = bc_ers_cmos_read(CMOS_TAPE_INDEX, &original);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;
    ZX_ASSERT(bc_ers_cmos_write(CMOS_TAPE_INDEX, original | CMOS_TAPE_ENABLE) == ZX_OK);

    ZX_ASSERT(bc_ers_tape_init() == ZX_OK);
    check_block(first_block, sizeof(first_block) - 1);
    zx_test_step_marker("first_block");

    check_block(second_block, sizeof(second_block) - 1);
    zx_test_step_marker("second_block");

    ZX_ASSERT(bc_ers_tape_init() == ZX_OK);
    check_block(first_block, sizeof(first_block) - 1);
    ZX_ASSERT(bc_ers_cmos_write(CMOS_TAPE_INDEX, original) == ZX_OK);
    zx_test_step_marker("rewind");

finish:
    zx_test_finish();
    return 0;
}
