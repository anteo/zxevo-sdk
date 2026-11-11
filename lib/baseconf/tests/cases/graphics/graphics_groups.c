#include <baseconf.h>
#include <zx/graphics.h>
#include <baseconf/video.h>
#include <graphics.h>

#include "bc_case.h"

int main(void) {
    bc_surface_t surface;
    uint8_t index = 0;
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ATM_320) == ZX_OK);
        surface = bc_screen_surface(BC_VIDEO_ATM_320, ZX_SCREEN_0);
        clg();

        ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
        ZX_ASSERT(zx_graphics_begin() == ZX_OK);
        zx_draw_hline(32, 80, 48);
        ZX_ASSERT(zx_graphics_begin() == ZX_OK);
        zx_draw_vline(80, 48, 80);
        ZX_ASSERT(zx_read_pixel_index(80, 64, &index) == ZX_OK);
        ZX_ASSERT(index == 7);
        ZX_ASSERT(bc_select_draw_surface(&surface) == ZX_BUSY);
        ZX_ASSERT(zx_graphics_end() == ZX_OK);

        /* Closing the inner group still leaves the outer group active. */
        ZX_ASSERT(bc_select_draw_surface(&surface) == ZX_BUSY);
        zx_draw_hline(32, 80, 80);
        ZX_ASSERT(zx_graphics_end() == ZX_OK);
        ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
        ZX_ASSERT(bc_select_draw_surface(&surface) == ZX_OK);
        zx_draw_vline(32, 48, 80);

        ZX_ASSERT(point(56, 48) == 1);
        ZX_ASSERT(point(80, 64) == 1);
        ZX_ASSERT(point(56, 80) == 1);
        ZX_ASSERT(point(32, 64) == 1);
        ZX_ASSERT(point(56, 64) == 0);
        zx_test_step_shot("nested");
    }
    zx_test_finish();
    return 0;
}
