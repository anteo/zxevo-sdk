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
    static const zx_ram_page_t screen0_pages[][2] = {
        {5, 0}, {5, 0}, {4, 5}, {1, 5}, {1, 5}, {1, 5}, {8, 0},
    };
    bc_window_config_t w1;
    zx_ram_page_t page0, page1;
    zx_window_t window0;
    uint8_t w1_writable;
    zx_status_t status = zx_set_video_mode(mode);
    if (status != ZX_OK) return status;

    page0 = screen0_pages[mode][0];
    page1 = screen0_pages[mode][1];
    status = zx_display_page(page0);
    if (status != ZX_OK) return status;
    status = bc_get_window_config(bc_get_active_map(), ZX_WINDOW_1, &w1);
    if (status != ZX_OK) return status;
    w1_writable = w1.kind == BC_RAM && !w1.substitute_from_7ffd_or_dos && !w1.write_protected;
    window0 = w1_writable && w1.physical_page == page0 ? ZX_WINDOW_1 : ZX_WINDOW_3;
    if (!page1) return zx_set_draw_buffer(mode, page0, window0);
    return zx_set_split_draw_buffer(mode, page0, window0, page1,
                                    w1_writable && w1.physical_page == page1 ? ZX_WINDOW_1
                                                                             : ZX_WINDOW_2);
}
