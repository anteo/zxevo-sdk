#include <baseconf.h>
#include <zx/graphics.h>
#include <baseconf/video.h>
#include <graphics.h>

#include "bc_case.h"

static void draw_mode(bc_video_mode_t mode, const char *tag) {
    int width, height, radius;
    zx_video_size_t size = {0, 0};
    if (bc_set_video_mode(mode) != ZX_OK) {
        zx_test_step_skip(tag, "video mode unavailable");
        return;
    }
    zx_set_paper(0);
    zx_set_ink(14);
    clg();
    cplot(3, 3, 14);
    ZX_ASSERT(cpoint(3, 3) == 14);
    ZX_ASSERT(multipoint(0, 5, -1, 3) == 1);
    ZX_ASSERT(multipoint(1, 4, 3, 2) == 4);
    ZX_ASSERT((uint16_t)multipoint(0, 16, 3, 3) == 0x8000u);
    ZX_ASSERT(multipoint(0, 17, 3, 3) == 0);

    /* Coincident symmetric points cancel for XOR. SET screenshots alone
     * cannot catch a change in how often those points are emitted. */
    zx_draw_ellipse_xor(12, 8, 2, 1);
    ZX_ASSERT(point(11, 7) == 1);
    ZX_ASSERT(point(13, 9) == 1);
    ZX_ASSERT(point(10, 8) == 0);
    ZX_ASSERT(point(12, 7) == 0);
    zx_draw_ellipse_xor(12, 8, 2, 1);

    xordrawb(20, 8, 3, 3);
    ZX_ASSERT(point(20, 8) == 1);
    ZX_ASSERT(point(22, 10) == 1);
    ZX_ASSERT(point(20, 9) == 1);
    ZX_ASSERT(point(21, 9) == 0);
    xordrawb(20, 8, 3, 3);

    xordrawb(20, 8, 1, 3);
    ZX_ASSERT(point(20, 9) == 1);
    xordrawb(20, 8, 1, 3);

    /* Clipping the left edge preserves the original dotted phase. */
    xorborder(-2, 8, 6, 5);
    ZX_ASSERT(point(0, 8) == 0);
    ZX_ASSERT(point(1, 8) == 1);
    ZX_ASSERT(point(3, 8) == 0);
    ZX_ASSERT(point(3, 9) == 1);
    ZX_ASSERT(point(3, 10) == 0);
    xorborder(-2, 8, 6, 5);
    xorborder(20, 8, 1, 5);
    ZX_ASSERT(point(20, 9) == 0);

    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK);
    width = (int)size.width;
    height = (int)size.height;
    radius = height >> 4;

    /* SET: line, horizontal/vertical line, circle and ellipse. */
    zx_draw_line_op(8, 12, width >> 2, height >> 2, ZX_DRAW_SET);
    zx_draw_hline_op(8, width >> 2, 12, ZX_DRAW_SET);
    zx_draw_vline_op(8, 12, height >> 2, ZX_DRAW_SET);
    zx_draw_circle_op(width >> 2, height >> 1, radius, ZX_DRAW_SET);
    zx_draw_ellipse_op(3 * width >> 2, height >> 1, width >> 3, height >> 4, ZX_DRAW_SET);

    /* Exercise XOR and CLEAR on line primitives too. */
    zx_draw_line_op(width >> 1, 8, width - 9, height >> 2, ZX_DRAW_XOR);
    zx_draw_hline_op((width >> 1) - 8, (width >> 1) + 8, 12, ZX_DRAW_CLEAR);

    zx_test_step_shot(tag);
}

int main(void) {
    if (bc_case_init() != ZX_OK) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
    draw_mode(BC_VIDEO_ZX_256, "zx256");
    draw_mode(BC_VIDEO_ZX_MULTICOLOR, "multicolor");
    draw_mode(BC_VIDEO_PENTAGON_256, "pentagon256");
    draw_mode(BC_VIDEO_ATM_320, "atm320");
    draw_mode(BC_VIDEO_ATM_640, "atm640");
    zx_test_finish();
    return 0;
}
