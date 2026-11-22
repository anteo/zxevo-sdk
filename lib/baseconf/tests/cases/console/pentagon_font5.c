#include "bc_case.h"

static void draw_samples(void) {
    uint8_t row;

    /* Stripes expose cleared transparent pixels and damage in the one-pixel
     * gap between cells. Each text row starts at a different pair phase. */
    for (row = 0; row < 192; ++row) {
        zx_set_ink((row & 1) ? 1 : 9);
        zx_draw_hline(0, 255, row);
    }
    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
    zx_set_ink(14);
    zx_set_paper(2);
    ZX_ASSERT(zx_console_draw_op(0, 0, "OPAQUE", ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(21, 0, "TRANSPARENT", ZX_TEXT_TRANSPARENT) == ZX_OK);
    for (row = 0; row < 4; ++row) {
        uint8_t y = 3 + row * 5;
        ZX_ASSERT(zx_console_draw_op(row, y, "MW.p# @0123456789", ZX_TEXT_OPAQUE) == ZX_OK);
        ZX_ASSERT(zx_console_draw_op(21 + row, y, "MW.p# @0123456789", ZX_TEXT_TRANSPARENT) ==
                  ZX_OK);
    }
    /* Exercise page/plane transitions at the bottom right, with dark ink
     * and bright paper to reverse the two brightness bits in packed pairs. */
    zx_set_ink(0);
    zx_set_paper(13);
    ZX_ASSERT(zx_console_draw_op(38, 22, "X #W", ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(38, 23, "X #W", ZX_TEXT_TRANSPARENT) == ZX_OK);
    zx_test_step_shot("opaque-and-transparent");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_case_select_video_mode(BC_VIDEO_PENTAGON_256) == ZX_OK);
        draw_samples();
    }
    zx_test_finish();
    return 0;
}
