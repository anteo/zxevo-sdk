#include <baseconf.h>

#include "bc_case.h"

static volatile uint8_t *const probe = (volatile uint8_t *)0x8123u;

static uint8_t page_is(bc_map_t map, zx_window_t window, uint8_t page) {
    bc_window_config_t config;
    return bc_get_window_config(map, window, &config) == ZX_OK && config.kind == BC_RAM &&
           config.physical_page == page && config.substitute_from_7ffd_or_dos == 0 &&
           config.write_protected == 0;
}

static void check_switching(void) {
    const bc_window_config_t alternate = {BC_RAM, 43, 0, 0};

    ZX_ASSERT(bc_get_active_map() == BC_MAP_0);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, 42) == ZX_OK);
    *probe = 0x2b;
    ZX_ASSERT(bc_configure_window(BC_MAP_1, ZX_WINDOW_2, &alternate) == ZX_OK);
    ZX_ASSERT(bc_get_active_map() == BC_MAP_0 && *probe == 0x2b);
    ZX_ASSERT(page_is(BC_MAP_0, ZX_WINDOW_2, 42));
    ZX_ASSERT(page_is(BC_MAP_1, ZX_WINDOW_2, 43));

    ZX_ASSERT(bc_select_map(BC_MAP_1) == ZX_OK);
    ZX_ASSERT(bc_get_active_map() == BC_MAP_1);
    *probe = 0xc4;
    ZX_ASSERT(bc_select_map(BC_MAP_0) == ZX_OK);
    ZX_ASSERT(bc_get_active_map() == BC_MAP_0 && *probe == 0x2b);
    ZX_ASSERT(bc_select_map(BC_MAP_1) == ZX_OK);
    ZX_ASSERT(bc_get_active_map() == BC_MAP_1 && *probe == 0xc4);
    ZX_ASSERT(bc_select_map(BC_MAP_0) == ZX_OK);
    zx_test_step_marker("switch_maps");
}

static void check_pinned_maps(void) {
    const bc_window_config_t alternate = {BC_RAM, 45, 0, 0};
    uint8_t resident = bc_get_pinned_windows();
    uint8_t system;

    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, 44) == ZX_OK);
    ZX_ASSERT(bc_configure_window(BC_MAP_1, ZX_WINDOW_3, &alternate) == ZX_OK);
    ZX_ASSERT(bc_get_active_map() == BC_MAP_0);
    bc_set_maps_prepared(0);
    ZX_ASSERT(bc_set_page_manager_enabled(1) == ZX_UNAVAILABLE);
    bc_set_maps_prepared(1);
    ZX_ASSERT(bc_set_page_manager_enabled(1) == ZX_OK);
    system = bc_readback_register(0x0c);
    ZX_ASSERT(bc_set_page_manager_enabled(0) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(bc_readback_register(0x0c) == system && *probe == 0x2b);

    /* W3 is scratch space. Pin it with differing maps to exercise the
     * rejection without risking either of the resident windows. */
    bc_set_pinned_windows((uint8_t)(resident | (1u << ZX_WINDOW_3)));
    ZX_ASSERT(bc_get_pinned_windows() == (resident | (1u << ZX_WINDOW_3)));
    ZX_ASSERT(bc_select_map(BC_MAP_1) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(bc_configure_window(BC_MAP_1, ZX_WINDOW_2, &alternate) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(bc_set_page_manager_enabled(1) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(bc_get_active_map() == BC_MAP_0 && *probe == 0x2b);
    ZX_ASSERT(page_is(BC_MAP_1, ZX_WINDOW_2, 43));

    bc_set_pinned_windows(resident);
    ZX_ASSERT(bc_select_map(BC_MAP_1) == ZX_OK);
    ZX_ASSERT(bc_get_active_map() == BC_MAP_1 && *probe == 0xc4);
    ZX_ASSERT(bc_select_map(BC_MAP_0) == ZX_OK);
    bc_set_maps_prepared(0);
    zx_test_step_marker("pinned_maps");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        check_switching();
        check_pinned_maps();
    }
    zx_test_finish();
    return 0;
}
