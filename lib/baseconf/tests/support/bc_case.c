#include "bc_case.h"

#ifndef BC_TEST_PINNED
#define BC_TEST_PINNED 0x03u
#endif

zx_status_t bc_case_init(void) {
    zx_test_init();
    bc_ers_set_profile(BC_ERS_NONE);
    bc_set_pinned_windows((uint8_t)BC_TEST_PINNED);
    zx_set_colors(COLOR_BLACK, COLOR_WHITE, COLOR_BLACK);
    return ZX_OK;
}

/* Use the test fixture's W3 scratch window and W2 when a second page
 * is needed. ERS window cases keep page 5 in their resident W1. */
zx_status_t bc_case_select_video_mode(bc_video_mode_t mode) {
    zx_video_surface_t surface;
    bc_window_config_t w1;
    uint8_t w1_writable;
    zx_status_t status = zx_set_video_mode(mode);
    if (status != ZX_OK) return status;

    surface = bc_screen_surface(mode, ZX_SCREEN_0);
    status = bc_get_window_config(bc_get_active_map(), ZX_WINDOW_1, &w1);
    if (status != ZX_OK) return status;
    w1_writable = w1.kind == BC_RAM && !w1.substitute_from_7ffd_or_dos && !w1.write_protected;
    if (w1_writable && w1.physical_page == surface.page0)
        return zx_draw_surface(&surface, ZX_WINDOW_1, surface.page1 ? ZX_WINDOW_2 : NULL);
    if (!surface.page1) return zx_draw_surface(&surface, ZX_WINDOW_3, NULL);
    return zx_draw_surface(&surface, ZX_WINDOW_3,
                           w1_writable && w1.physical_page == surface.page1 ? ZX_WINDOW_1
                                                                            : ZX_WINDOW_2);
}
