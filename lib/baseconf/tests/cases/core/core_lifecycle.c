#include <baseconf.h>

#include "bc_case.h"

static void check_reinitialize(void) {
    volatile uint8_t *const probe = (volatile uint8_t *)0xc123u;
    bc_window_config_t config = {BC_RAM, 53, 0, 0};
    bc_window_lease_t lease = {0};
    bc_map_t map = bc_get_active_map();
    uint8_t page_register = (uint8_t)(4u * map + ZX_WINDOW_3);

    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, 52) == ZX_OK);
    *probe = 0xa9;
    ZX_ASSERT(zx_shutdown() == ZX_OK);
    ZX_ASSERT(zx_shutdown() == ZX_OK);
    ZX_ASSERT(bc_get_window_config(map, ZX_WINDOW_3, &config) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, 53) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(bc_set_write_protection(ZX_WINDOW_3, 1) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(bc_window_acquire(ZX_WINDOW_3, config, &lease) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(!lease.active);
    ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(bc_readback_register(page_register) == (uint8_t)~52u);
    ZX_ASSERT(*probe == 0xa9);
    ZX_ASSERT(zx_init() == ZX_OK);
    ZX_ASSERT(bc_get_window_config(map, ZX_WINDOW_3, &config) == ZX_OK);
    ZX_ASSERT(config.kind == BC_RAM && config.physical_page == 52);
    ZX_ASSERT(*probe == 0xa9);
    zx_test_step_marker("restart");
}

static void check_busy_shutdown(void) {
    const bc_window_config_t temporary = {BC_RAM, 53, 0, 0};
    bc_window_lease_t lease = {0};
    bc_paging_snapshot_t snapshot;
    zx_status_t status = bc_window_acquire(ZX_WINDOW_3, temporary, &lease);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(zx_shutdown() == ZX_BUSY);
        ZX_ASSERT(zx_init() == ZX_BUSY);
        ZX_ASSERT(bc_get_paging_state(&snapshot) == ZX_OK);
        ZX_ASSERT(bc_window_release(&lease) == ZX_OK);
    }
    ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
    status = zx_graphics_begin();
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(zx_shutdown() == ZX_BUSY);
        ZX_ASSERT(zx_init() == ZX_BUSY);
        ZX_ASSERT(bc_get_paging_state(&snapshot) == ZX_OK);
        ZX_ASSERT(zx_graphics_end() == ZX_OK);
    }
    ZX_ASSERT(zx_shutdown() == ZX_OK);
    ZX_ASSERT(bc_get_paging_state(&snapshot) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_init() == ZX_OK);
    zx_test_step_marker("busy_shutdown");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        check_reinitialize();
        check_busy_shutdown();
    }
    zx_test_finish();
    return 0;
}
