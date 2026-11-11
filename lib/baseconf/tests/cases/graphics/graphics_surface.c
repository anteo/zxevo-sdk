#include <baseconf.h>
#include <graphics.h>

#include "bc_case.h"

static void check_buffers(void) {
    bc_surface_t front = bc_screen_surface(BC_VIDEO_ZX_256, ZX_SCREEN_0);
    bc_surface_t back = bc_screen_surface(BC_VIDEO_ZX_256, ZX_SCREEN_1);
    uint8_t index = 0xff;

    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, back.page0) == ZX_OK);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, front.page0) == ZX_OK);

    ZX_ASSERT(zx_select_draw_screen(ZX_SCREEN_0) == ZX_OK);
    zx_set_ink(6);
    clg();
    fillb(32, 48, 48, 32);

    ZX_ASSERT(zx_select_draw_screen(ZX_SCREEN_1) == ZX_OK);
    zx_set_ink(5);
    clg();
    zx_draw_line(112, 48, 160, 80);
    zx_draw_line(160, 48, 112, 80);
    ZX_ASSERT(BC_PAGING_SCREEN(bc_readback_register(0x0a)) == ZX_SCREEN_0);
    ZX_ASSERT(zx_read_pixel_index(136, 64, &index) == ZX_OK && index == 5);
    ZX_ASSERT(point(56, 64) == 0);
    zx_test_step_shot("front");

    ZX_ASSERT(zx_select_draw_screen(ZX_SCREEN_0) == ZX_OK);
    ZX_ASSERT(zx_show_screen(ZX_SCREEN_1) == ZX_OK);
    ZX_ASSERT(BC_PAGING_SCREEN(bc_readback_register(0x0a)) == ZX_SCREEN_1);
    ZX_ASSERT(zx_read_pixel_index(56, 64, &index) == ZX_OK && index == 6);
    ZX_ASSERT(point(136, 64) == 0);
    zx_test_step_shot("back");

    ZX_ASSERT(zx_show_screen(ZX_SCREEN_0) == ZX_OK);
    ZX_ASSERT(zx_read_pixel_index(256, 0, &index) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_read_pixel_index(0, 192, &index) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_read_pixel_index(0, 0, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(index == 6);
}

static void check_rejected_surfaces(void) {
    const bc_surface_t unmapped = {BC_VIDEO_ZX_256, 63, 63};
    uint8_t index = 0xff;

    ZX_ASSERT(bc_select_draw_surface(&unmapped) == ZX_OK);
    ZX_ASSERT(zx_graphics_begin() == ZX_UNAVAILABLE);
    ZX_ASSERT(zx_read_pixel_index(0, 0, &index) == ZX_UNAVAILABLE);
    ZX_ASSERT(index == 0xff);
    ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);

    ZX_ASSERT(bc_set_video_mode(BC_VIDEO_EVO_TEXT_80) == ZX_OK);
    ZX_ASSERT(zx_graphics_begin() == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_read_pixel_index(0, 0, &index) == ZX_UNSUPPORTED);
    ZX_ASSERT(index == 0xff);
    ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
    zx_test_step_marker("rejected");
}

static void check_offscreen_format(void) {
    const bc_surface_t surface = bc_screen_surface(BC_VIDEO_ATM_320, ZX_SCREEN_1);
    zx_video_size_t size = {0, 0};
    uint8_t index = 0xff;

    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, surface.page0) == ZX_OK);
    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, surface.page1) == ZX_OK);
    ZX_ASSERT(bc_select_draw_surface(&surface) == ZX_OK);
    ZX_ASSERT(bc_get_video_mode() == BC_VIDEO_ZX_256);
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK && size.width == 320 && size.height == 200);
    ZX_ASSERT(bc_resync() == ZX_OK);
    zx_set_ink(9);
    zx_draw_line(300, 199, 319, 199);
    ZX_ASSERT(zx_read_pixel_index(319, 199, &index) == ZX_OK && index == 9);
    ZX_ASSERT(zx_show_screen(ZX_SCREEN_1) == ZX_OK);
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK && size.width == 320);
    ZX_ASSERT(bc_get_video_mode() == BC_VIDEO_ZX_256);
    index = 0xff;
    ZX_ASSERT(zx_read_pixel_index(300, 199, &index) == ZX_OK && index == 9);
    ZX_ASSERT(zx_show_screen(ZX_SCREEN_0) == ZX_OK);
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
        check_buffers();
        check_offscreen_format();
        check_rejected_surfaces();
    }
    zx_test_finish();
    return 0;
}
