#include <arch/z80.h>
#include <baseconf.h>
#include <graphics.h>

#include "bc_case.h"

static void check_rejected_surfaces(void) {
    uint8_t index = 0xff;

    ZX_ASSERT(zx_set_draw_buffer(BC_VIDEO_ZX_256, 63, ZX_WINDOW_1) == ZX_BUSY);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, 63) == ZX_OK);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_UNAVAILABLE);
    ZX_ASSERT(zx_graphics_begin() == ZX_UNAVAILABLE);
    ZX_ASSERT(zx_read_pixel_index(0, 0, &index) == ZX_UNAVAILABLE);
    ZX_ASSERT(index == 0xff);
    ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);

    ZX_ASSERT(zx_set_draw_buffer(BC_VIDEO_ZX_256, 63, ZX_WINDOW_3) == ZX_OK);
    ZX_ASSERT(zx_graphics_begin() == ZX_OK);
    ZX_ASSERT(zx_graphics_end() == ZX_OK);
    ZX_ASSERT(zx_display_page(63) == ZX_INVALID_ARGUMENT);
    /* An immediate setter that remaps W3 discards its prepared mapping. */
    ZX_ASSERT(zx_prepare_draw_buffer(0, BC_VIDEO_ZX_256, 5, ZX_WINDOW_3) == ZX_OK);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
    ZX_ASSERT(zx_set_draw_buffer(BC_VIDEO_ZX_256, 63, ZX_WINDOW_3) == ZX_OK);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_UNAVAILABLE);
    ZX_ASSERT(bc_readback_register(4u * bc_get_active_map() + 3u) == (uint8_t)~63u);

    ZX_ASSERT(bc_case_select_video_mode(BC_VIDEO_EVO_TEXT_80) == ZX_OK);
    ZX_ASSERT(zx_graphics_begin() == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_read_pixel_index(0, 0, &index) == ZX_UNSUPPORTED);
    ZX_ASSERT(index == 0xff);
    ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
    zx_test_step_marker("rejected");
}

/* Reuse the same slot as each half of the pair changes independently.
 * Physical pages 255 and 0 exercise both extremes of the inverted port byte. */
static void check_prepared_writes(uint8_t map_register) {
    static const zx_ram_page_t pairs[][2] = {{3, 7}, {255, 7}, {3, 0}, {1, 5}};
    uint8_t i;
    for (i = 0; i < sizeof(pairs) / sizeof(pairs[0]); ++i) {
        ZX_ASSERT(zx_prepare_split_draw_buffer(1, BC_VIDEO_ATM_320, pairs[i][0], ZX_WINDOW_2,
                                               pairs[i][1], ZX_WINDOW_3) == ZX_OK);
        ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
        ZX_ASSERT(zx_select_draw_buffer(1) == ZX_OK);
        ZX_ASSERT(bc_readback_register(map_register + 2u) == (uint8_t)~pairs[i][0]);
        ZX_ASSERT(bc_readback_register(map_register + 3u) == (uint8_t)~pairs[i][1]);
    }
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
}

static void check_offscreen_format(void) {
    zx_video_size_t size = {0, 0};
    uint8_t index = 0xff;
    uint8_t map_register = 4u * bc_get_active_map();
    uint8_t pins = bc_get_pinned_windows();

    ZX_ASSERT(zx_set_draw_buffer(BC_VIDEO_ATM_320, 3, ZX_WINDOW_2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_prepare_split_draw_buffer(0, BC_VIDEO_ATM_320, 3, ZX_WINDOW_2, 7, ZX_WINDOW_3) ==
              ZX_OK);
    ZX_ASSERT(zx_prepare_draw_buffer(1, ZX_VIDEO_ZX_256, 7, ZX_WINDOW_3) == ZX_OK);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
    ZX_ASSERT(zx_get_video_mode() == BC_VIDEO_ZX_256);
    ZX_ASSERT(BC_PAGING_SCREEN(bc_readback_register(0x0a)) == ZX_SCREEN_0);
    ZX_ASSERT(zx_display_buffer(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(BC_PAGING_SCREEN(bc_readback_register(0x0a)) == ZX_SCREEN_0);
    ZX_ASSERT(zx_set_video_mode(BC_VIDEO_ATM_320) == ZX_OK);
    ZX_ASSERT(zx_select_draw_buffer(1) == ZX_OK);
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK && size.width == 256 && size.height == 192);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
    ZX_ASSERT(zx_display_buffer(0) == ZX_OK);
    ZX_ASSERT(zx_get_video_mode() == BC_VIDEO_ATM_320);
    ZX_ASSERT(BC_PAGING_SCREEN(bc_readback_register(0x0a)) == ZX_SCREEN_1);
    ZX_ASSERT(bc_readback_register(map_register + 2u) == (uint8_t)~3u);
    ZX_ASSERT(bc_readback_register(map_register + 3u) == (uint8_t)~7u);
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK && size.width == 320 && size.height == 200);

    /* Both ATM frames reuse W2/W3. Preparation preserves the selected frame.
     * Selection changes both CPU banks; presentation is a separate operation. */
    zx_set_ink(2);
    zx_draw_line(8, 8, 9, 8);
    ZX_ASSERT(zx_prepare_split_draw_buffer(1, BC_VIDEO_ATM_320, 1, ZX_WINDOW_2, 5, ZX_WINDOW_3) ==
              ZX_OK);
    ZX_ASSERT(zx_read_pixel_index(8, 8, &index) == ZX_OK && index == 2);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
    bc_set_pinned_windows(pins | ZX_WINDOW_MASK(ZX_WINDOW_3));
    /* Even the currently mapped pair needs a free W3 to alternate with its peer. */
    ZX_ASSERT(zx_prepare_split_draw_buffer(0, BC_VIDEO_ATM_320, 3, ZX_WINDOW_2, 7, ZX_WINDOW_3) ==
              ZX_BUSY);
    ZX_ASSERT(zx_select_draw_buffer(1) == ZX_BUSY);
    ZX_ASSERT(bc_readback_register(map_register + 2u) == (uint8_t)~3u);
    bc_set_pinned_windows(pins);
    ZX_ASSERT(zx_select_draw_buffer(1) == ZX_OK);
    ZX_ASSERT(bc_readback_register(map_register + 2u) == (uint8_t)~1u);
    ZX_ASSERT(bc_readback_register(map_register + 3u) == (uint8_t)~5u);
    ZX_ASSERT(BC_PAGING_SCREEN(bc_readback_register(0x0a)) == ZX_SCREEN_1);
    zx_set_ink(4);
    zx_draw_line(8, 8, 9, 8);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
    ZX_ASSERT(zx_read_pixel_index(8, 8, &index) == ZX_OK && index == 2);
    ZX_ASSERT(zx_select_draw_buffer(1) == ZX_OK);
    ZX_ASSERT(zx_read_pixel_index(8, 8, &index) == ZX_OK && index == 4);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
    /* A one-off setter can change the renderer without changing either bank. */
    ZX_ASSERT(zx_set_draw_buffer(ZX_VIDEO_ZX_256, 3, ZX_WINDOW_2) == ZX_OK);
    ZX_ASSERT(zx_select_draw_buffer(1) == ZX_OK);
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK && size.width == 320 && size.height == 200);
    ZX_ASSERT(zx_read_pixel_index(8, 8, &index) == ZX_OK && index == 4);
    ZX_ASSERT(zx_select_draw_buffer(0) == ZX_OK);
    check_prepared_writes(map_register);
    ZX_ASSERT(zx_set_video_mode(ZX_VIDEO_ZX_256) == ZX_OK);
    ZX_ASSERT(zx_display_page(5) == ZX_OK);
    ZX_ASSERT(zx_get_video_mode() == BC_VIDEO_ZX_256);
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK && size.width == 320 && size.height == 200);
    ZX_ASSERT(bc_resync() == ZX_OK);
    zx_set_ink(9);
    zx_draw_line(300, 199, 319, 199);
    ZX_ASSERT(zx_read_pixel_index(319, 199, &index) == ZX_OK && index == 9);
    ZX_ASSERT(zx_display_page(7) == ZX_OK);
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK && size.width == 320);
    ZX_ASSERT(zx_get_video_mode() == BC_VIDEO_ZX_256);
    index = 0xff;
    ZX_ASSERT(zx_read_pixel_index(300, 199, &index) == ZX_OK && index == 9);
    ZX_ASSERT(zx_display_page(5) == ZX_OK);
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(zx_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
        ZX_ASSERT(zx_display_page(5) == ZX_OK);
        check_offscreen_format();
        check_rejected_surfaces();
    }
    zx_test_finish();
    return 0;
}
