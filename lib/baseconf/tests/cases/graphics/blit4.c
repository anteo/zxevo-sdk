#include <baseconf.h>
#include "bc_case.h"
#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 200
#include "../../../../common/tests/support/blit4_checks.h"
int main(void) {
    bc_window_lease_t lease;
    bc_window_config_t config;
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(zx_set_split_draw_buffer(BC_VIDEO_ATM_320, 3, ZX_WINDOW_2, 7, ZX_WINDOW_3) == ZX_OK);
        check_blit_pixels();
        check_blit_arguments();
        ZX_ASSERT(zx_graphics_begin() == ZX_OK);
        ZX_ASSERT(zx_blit4(&image4, 0, 30) == ZX_OK);
        ZX_ASSERT(zx_graphics_end() == ZX_OK);
        ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
        ZX_ASSERT(bc_get_window_config(bc_get_active_map(), ZX_WINDOW_3, &config) == ZX_OK);
        ZX_ASSERT(bc_window_acquire(ZX_WINDOW_3, config, &lease) == ZX_OK);
        ZX_ASSERT(zx_blit4(&image4, 0, 0) == ZX_BUSY);
        ZX_ASSERT(bc_window_release(&lease) == ZX_OK);
        ZX_ASSERT(zx_set_split_draw_buffer(BC_VIDEO_ATM_320, 62, ZX_WINDOW_2, 63, ZX_WINDOW_1) ==
                  ZX_BUSY);
        ZX_ASSERT(bc_get_window_config(bc_get_active_map(), ZX_WINDOW_2, &config) == ZX_OK);
        ZX_ASSERT(config.physical_page == 3);
        ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, 63) == ZX_OK);
        ZX_ASSERT(zx_blit4(&image4, 0, 0) == ZX_UNAVAILABLE);
        ZX_ASSERT(zx_set_draw_buffer(BC_VIDEO_ZX_256, 5, ZX_WINDOW_3) == ZX_OK);
        ZX_ASSERT(zx_blit4(&image4, 0, 0) == ZX_UNSUPPORTED);
        zx_test_step_marker("surface-leases");
    }
    zx_test_finish();
    return 0;
}
