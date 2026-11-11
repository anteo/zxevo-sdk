#include <baseconf.h>

#include "bc_case.h"

static const char bin_mask[49] = "BIN";
static const uint16_t disk_order[] = {0, 1, 2};
static const uint16_t sorted_order[] = {2, 1, 0};
static const uint16_t directories_only[] = {2};

static void check_order(const bc_ers_fat_file_list_t *list, const uint16_t *expected,
                        uint16_t count) {
    const volatile uint16_t *entries = (const volatile uint16_t *)0xc000u;
    bc_window_config_t config = {BC_RAM, list->ram_sortfiles_page, 0, 0};
    bc_window_lease_t lease;
    zx_status_t status;
    uint16_t i;

    ZX_ASSERT(list->count == count);
    if (list->count != count) return;
    status = bc_window_acquire(ZX_WINDOW_3, config, &lease);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    for (i = 0; i < count; ++i) ZX_ASSERT(entries[i] == expected[i]);
    ZX_ASSERT(bc_window_release(&lease) == ZX_OK);
}

int main(void) {
    bc_ers_device_info_t device;
    bc_ers_fat_file_list_t list;
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

    ZX_ASSERT(bc_ers_fat_set_extension_mask(bin_mask) == ZX_OK);
    status = bc_ers_fat_find_file_items(&list);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) check_order(&list, directories_only, 1);
    zx_test_step_marker("filter");

    ZX_ASSERT(bc_ers_fat_set_extension_mask(0) == ZX_OK);
    status = bc_ers_fat_find_file_items(&list);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        check_order(&list, disk_order, 3);
        ZX_ASSERT(bc_ers_fat_sort_found_files() == ZX_OK);
        check_order(&list, sorted_order, 3);
    }
    zx_test_step_marker("sort");
    zx_test_finish();
    return 0;
}
