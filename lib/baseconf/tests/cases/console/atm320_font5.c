#include "bc_case.h"

static void draw_samples(void) {
    uint8_t y;

    /* Stripes show transparent paper and the untouched sixth pixel. */
    for (y = 0; y < 200; ++y) {
        zx_set_ink((y & 1) ? 1 : 9);
        zx_draw_hline(0, 319, y);
    }
    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
    zx_set_ink(14);
    zx_set_paper(2);
    ZX_ASSERT(zx_console_draw_op(0, 0, "OPAQUE", ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(27, 0, "TRANSPARENT", ZX_TEXT_TRANSPARENT) == ZX_OK);
    /* Each group starts on a different packed pair. The right group also
     * crosses x=255, exercising the high byte of the horizontal coordinate. */
    for (y = 0; y < 4; ++y) {
        ZX_ASSERT(zx_console_draw_op(y, 2 + 5 * y, "MW.p# @0123456789", ZX_TEXT_OPAQUE) ==
                  ZX_OK);
        ZX_ASSERT(zx_console_draw_op(27 + y, 2 + 5 * y, "MW.p# @0123456789",
                                     ZX_TEXT_TRANSPARENT) == ZX_OK);
    }
    zx_set_ink(0);
    zx_set_paper(13);
    ZX_ASSERT(zx_console_draw_op(49, 23, "X #W", ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(49, 24, "X #W", ZX_TEXT_TRANSPARENT) == ZX_OK);
    zx_test_step_shot("opaque-and-transparent");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_case_select_video_mode(BC_VIDEO_ATM_320) == ZX_OK);
        draw_samples();
    }
    zx_test_finish();
    return 0;
}
