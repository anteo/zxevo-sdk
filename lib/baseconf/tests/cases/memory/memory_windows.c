#include <baseconf.h>

#include "bc_case.h"

enum { FIRST_PAGE = 40, SECOND_PAGE = 41, W2_PROTECT_BIT = 4 };

static volatile uint8_t *const first_byte = (volatile uint8_t *)0x8000u;
static volatile uint8_t *const last_byte = (volatile uint8_t *)0xbfffu;

static uint8_t window_matches(bc_map_t map, uint8_t page, uint8_t write_protected) {
    bc_window_config_t config;
    return bc_get_window_config(map, ZX_WINDOW_2, &config) == ZX_OK && config.kind == BC_RAM &&
           config.physical_page == page && config.substitute_from_7ffd_or_dos == 0 &&
           config.write_protected == write_protected;
}

static void check_mapping(bc_map_t map) {
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, FIRST_PAGE) == ZX_OK);
    *first_byte = 0x39;
    *last_byte = 0xa6;
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, SECOND_PAGE) == ZX_OK);
    *first_byte = 0xc5;
    *last_byte = 0x5a;
    ZX_ASSERT(window_matches(map, SECOND_PAGE, 0));

    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, FIRST_PAGE) == ZX_OK);
    ZX_ASSERT(window_matches(map, FIRST_PAGE, 0));
    ZX_ASSERT(*first_byte == 0x39 && *last_byte == 0xa6);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, SECOND_PAGE) == ZX_OK);
    ZX_ASSERT(*first_byte == 0xc5 && *last_byte == 0x5a);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, FIRST_PAGE) == ZX_OK);

    ZX_ASSERT((bc_get_pinned_windows() & 3) == 3);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_0, SECOND_PAGE) == ZX_BUSY);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_1, SECOND_PAGE) == ZX_BUSY);
    zx_test_step_marker("mapping");
}

static void check_protection(bc_map_t map) {
    uint8_t mask = (uint8_t)(W2_PROTECT_BIT << (4 * map));
    ZX_ASSERT(bc_set_write_protection(ZX_WINDOW_2, 1) == ZX_OK);
    ZX_ASSERT(window_matches(map, FIRST_PAGE, 1));
    ZX_ASSERT((bc_readback_register(0x12) & mask) != 0);
    *first_byte = 0x44;
    *last_byte = 0x88;
    ZX_ASSERT(*first_byte == 0x39 && *last_byte == 0xa6);

    ZX_ASSERT(bc_set_write_protection(ZX_WINDOW_2, 0) == ZX_OK);
    ZX_ASSERT(window_matches(map, FIRST_PAGE, 0));
    ZX_ASSERT((bc_readback_register(0x12) & mask) == 0);
    *first_byte = 0x44;
    *last_byte = 0x88;
    ZX_ASSERT(*first_byte == 0x44 && *last_byte == 0x88);
    zx_test_step_marker("write_protection");
}

static void check_lease(bc_map_t map) {
    bc_window_lease_t lease = {0};
    bc_window_lease_t other = {0};
    const bc_window_config_t temporary = {BC_RAM, SECOND_PAGE, 0, 0};

    ZX_ASSERT(bc_set_write_protection(ZX_WINDOW_2, 1) == ZX_OK);
    ZX_ASSERT(bc_window_acquire(ZX_WINDOW_2, temporary, &lease) == ZX_OK);
    ZX_ASSERT(window_matches(map, SECOND_PAGE, 0));
    ZX_ASSERT(*first_byte == 0xc5 && *last_byte == 0x5a);
    *first_byte = 0x63;

    ZX_ASSERT(bc_window_acquire(ZX_WINDOW_3, temporary, &other) == ZX_BUSY);
    ZX_ASSERT(bc_window_release(&other) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, FIRST_PAGE) == ZX_BUSY);
    ZX_ASSERT(bc_select_map(map) == ZX_BUSY);
    ZX_ASSERT(bc_resync() == ZX_BUSY);
    ZX_ASSERT(*first_byte == 0x63);

    ZX_ASSERT(bc_window_release(&lease) == ZX_OK);
    ZX_ASSERT(bc_window_release(&lease) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(window_matches(map, FIRST_PAGE, 1));
    *first_byte = 0;
    ZX_ASSERT(*first_byte == 0x44 && *last_byte == 0x88);

    ZX_ASSERT(bc_window_acquire(ZX_WINDOW_2, temporary, &other) == ZX_OK);
    ZX_ASSERT(*first_byte == 0x63);
    ZX_ASSERT(bc_window_release(&other) == ZX_OK);
    ZX_ASSERT(bc_set_write_protection(ZX_WINDOW_2, 0) == ZX_OK);
    zx_test_step_marker("lease");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_map_t map = bc_get_active_map();
        check_mapping(map);
        check_protection(map);
        check_lease(map);
    }
    zx_test_finish();
    return 0;
}
