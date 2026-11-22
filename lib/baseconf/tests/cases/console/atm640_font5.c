#include "bc_case.h"

/* The low bits are deliberately set outside the custom glyph's width. */
static const uint8_t rows[8] = {0xaf, 0x57, 0xff, 0x07, 0xdf, 0x37, 0x8f, 0xff};

static void draw_samples(void) {
    uint8_t y;
    zx_font_t custom = zx_font5;
    zx_set_ink(11);
    zx_set_paper(1);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    for (y = 2; y < 200; y += 4) zx_draw_hline(0, 639, y);

    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
    zx_set_ink(14);
    zx_set_paper(2);
    ZX_ASSERT(zx_console_draw_op(1, 0, "OPAQUE", ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(59, 0, "TRANSPARENT", ZX_TEXT_TRANSPARENT) == ZX_OK);
    /* Eight consecutive cells start at all even positions within a 16-pixel
     * group. The right-hand samples cross x=512 and reach the bottom row. */
    for (y = 0; y < 8; ++y) {
        ZX_ASSERT(zx_console_draw_op(y, 2 + 2 * y, "MW.p# @0123456789", ZX_TEXT_OPAQUE) == ZX_OK);
        ZX_ASSERT(zx_console_draw_op(72 + y, 2 + 2 * y, "MW.p# @0123456789", ZX_TEXT_TRANSPARENT) ==
                  ZX_OK);
    }
    ZX_ASSERT(zx_console_draw_op(100, 23, "p #.MW", ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(100, 24, "p #.MW", ZX_TEXT_TRANSPARENT) == ZX_OK);

    custom.glyphs = rows;             /* space is glyph zero */
    custom.width = 4;
    custom.height = 7;
    custom.advance = 5;
    ZX_ASSERT(zx_console_set_font(&custom) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(1, 19, "        ", ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(73, 19, "        ", ZX_TEXT_TRANSPARENT) == ZX_OK);
    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
    zx_test_step_shot("opaque-and-transparent");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_case_select_video_mode(BC_VIDEO_ATM_640) == ZX_OK);
        draw_samples();
    }
    zx_test_finish();
    return 0;
}
