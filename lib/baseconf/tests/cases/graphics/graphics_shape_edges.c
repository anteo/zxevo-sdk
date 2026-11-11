#include <baseconf.h>
#include <graphics.h>
#include <stdlib.h>

#include "bc_case.h"

static void check_clipped_curves(int right, int bottom) {
    int x, y;

    zx_draw_circle(0, 20, 3);
    for (y = -4; y <= 4; ++y) {
        int dy = abs(y);
        for (x = 0; x <= 4; ++x) {
            int expected = (x == 3 && dy <= 1) || (x <= 1 && dy == 3) || (x == 2 && dy == 2);
            ZX_ASSERT(point(x, 20 + y) == expected);
            ZX_ASSERT(point(right - x, 20 + y) == 0);
        }
    }

    zx_draw_ellipse(right, bottom, 2, 1);
    for (y = 0; y <= 2; ++y) {
        for (x = 0; x <= 3; ++x) {
            int expected = (x == 2 && y == 0) || (x <= 1 && y == 1);
            ZX_ASSERT(point(right - x, bottom - y) == expected);
            ZX_ASSERT(point(x, bottom - y) == 0);
        }
    }
}

static void check_degenerate_curves(int right) {
    int x, y;

    zx_draw_circle(20, 48, 0);
    zx_draw_circle(36, 48, -3);
    zx_draw_ellipse(48, 48, -2, 1);
    zx_draw_ellipse(60, 48, 2, -1);
    zx_draw_circle(-8, 48, 3);
    zx_draw_ellipse(right + 8, 48, 2, 1);
    for (y = 44; y <= 52; ++y) {
        for (x = 0; x <= 64; ++x) ZX_ASSERT(point(x, y) == (x == 20 && y == 48));
        for (x = right - 8; x <= right; ++x) ZX_ASSERT(point(x, y) == 0);
    }

    zx_draw_ellipse(32, 68, 0, 4);
    zx_draw_ellipse(48, 68, 4, 0);
    zx_draw_ellipse(64, 68, 0, 0);
    for (y = 63; y <= 73; ++y) {
        for (x = 31; x <= 65; ++x) {
            int expected = (x == 32 && y >= 64 && y <= 72) || (y == 68 && x >= 44 && x <= 52) ||
                           (x == 64 && y == 68);
            ZX_ASSERT(point(x, y) == expected);
        }
    }
}

static void check_reversed_axes(int right, int bottom) {
    int i;
    zx_draw_hline(12, -4, 104);
    zx_draw_vline(right - 12, bottom + 4, bottom - 12);
    for (i = 0; i <= 13; ++i) {
        ZX_ASSERT(point(i, 104) == (i <= 12));
        ZX_ASSERT(point(right - 12, bottom - i) == (i <= 12));
    }
    ZX_ASSERT(point(right, 104) == 0);
    ZX_ASSERT(point(right - 12, 0) == 0);
}

static void check_shorthands(void) {
    zx_draw_plot(14, 30);
    ZX_ASSERT(point(14, 30) == 1 && point(30, 14) == 0);
    zx_draw_plot_xor(14, 30);
    ZX_ASSERT(point(14, 30) == 0);

    zx_draw_line(12, 28, 16, 32);
    zx_draw_line_xor(12, 28, 16, 32);
    ZX_ASSERT(point(14, 30) == 0);
    zx_draw_line_xor(12, 28, 16, 32);
    ZX_ASSERT(point(14, 30) == 1);
    zx_draw_line_clear(12, 28, 16, 32);
    ZX_ASSERT(point(14, 30) == 0);

    zx_draw_hline(16, 12, 30);
    zx_draw_hline_xor(16, 12, 30);
    ZX_ASSERT(point(14, 30) == 0);
    zx_draw_hline_xor(16, 12, 30);
    ZX_ASSERT(point(14, 30) == 1 && point(14, 31) == 0);
    zx_draw_hline_clear(16, 12, 30);
    ZX_ASSERT(point(14, 30) == 0);

    zx_draw_vline(14, 32, 28);
    zx_draw_vline_xor(14, 32, 28);
    ZX_ASSERT(point(14, 30) == 0);
    zx_draw_vline_xor(14, 32, 28);
    ZX_ASSERT(point(14, 30) == 1 && point(15, 30) == 0);
    zx_draw_vline_clear(14, 32, 28);
    ZX_ASSERT(point(14, 30) == 0);

    zx_draw_circle(28, 30, 3);
    zx_draw_circle_xor(28, 30, 3);
    ZX_ASSERT(point(31, 31) == 0 && point(31, 30) == 1);
    zx_draw_circle_xor(28, 30, 3);
    ZX_ASSERT(point(31, 31) == 1 && point(28, 30) == 0);
    zx_draw_circle_clear(28, 30, 3);
    ZX_ASSERT(point(31, 31) == 0 && point(31, 30) == 0);

    zx_draw_ellipse(40, 30, 2, 1);
    ZX_ASSERT(point(42, 30) == 1 && point(39, 31) == 1);
    zx_draw_ellipse_xor(40, 30, 2, 1);
    ZX_ASSERT(point(42, 30) == 1 && point(39, 31) == 0);
    zx_draw_ellipse_xor(40, 30, 2, 1);
    ZX_ASSERT(point(39, 31) == 1);
    zx_draw_ellipse_clear(40, 30, 2, 1);
    ZX_ASSERT(point(42, 30) == 0 && point(39, 31) == 0);

    zx_draw_fill_rect(54, 30, 4, 2);
    ZX_ASSERT(point(54, 30) == 1 && point(57, 31) == 1 && point(58, 30) == 0);
    zx_draw_clear_rect(55, 30, 2, 2);
    ZX_ASSERT(point(54, 30) == 1 && point(55, 30) == 0 && point(56, 31) == 0 && point(57, 31) == 1);
    zx_draw_clear_rect(54, 30, 4, 2);
}

static void check_mode(bc_video_mode_t mode, const char *tag) {
    zx_video_size_t size = {0, 0};
    zx_status_t status = bc_set_video_mode(mode);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_step_marker(tag);
        return;
    }
    clg();
    check_shorthands();
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK);
    check_clipped_curves((int)size.width - 1, (int)size.height - 1);
    check_degenerate_curves((int)size.width - 1);
    check_reversed_axes((int)size.width - 1, (int)size.height - 1);
    zx_test_step_shot(tag);
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        check_mode(BC_VIDEO_ZX_256, "zx256");
        check_mode(BC_VIDEO_ATM_320, "atm320");
    }
    zx_test_finish();
    return 0;
}
