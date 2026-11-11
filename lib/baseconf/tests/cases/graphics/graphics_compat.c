#include <baseconf.h>
#include <graphics.h>
#include <stdlib.h>

#include "bc_case.h"

static void check_pixels(int right, int bottom) {
    plot(17, 22);
    plot(18, 22);
    ZX_ASSERT(cpoint(17, 22) == 6 && cpoint(18, 22) == 6);
    xorplot(17, 22);
    ZX_ASSERT(cpoint(17, 22) == 0 && cpoint(18, 22) == 6);
    xorplot(17, 22);
    ZX_ASSERT(cpoint(17, 22) == 6);
    unplot(17, 22);
    ZX_ASSERT(cpoint(17, 22) == 0 && cpoint(18, 22) == 6);

    plot(-1, 22);
    plot(right + 1, 22);
    plot(18, bottom + 1);
    ZX_ASSERT(point(right, 22) == 0 && point(0, 22) == 0);
    ZX_ASSERT(point(18, 0) == 0 && point(18, bottom) == 0);
}

static uint8_t wide_circle_matches(uint8_t outline, uint8_t coincident) {
    int x, y;
    for (y = -4; y <= 4; ++y) {
        int dy = abs(y);
        for (x = -4; x <= 4; ++x) {
            int dx = abs(x);
            uint8_t expected = 0;
            if ((dx == 3 && dy == 1) || (dx == 1 && dy == 3)) expected = outline;
            if ((dx == 3 && dy == 0) || (dx == 0 && dy == 3) || (dx == 2 && dy == 2))
                expected = coincident;
            if (point(40 + x, 34 + y) != expected) return 0;
        }
    }
    return 1;
}

static void check_wide_circles(void) {
    circle(40, 34, 3, 1);
    ZX_ASSERT(wide_circle_matches(1, 1));
    uncircle(40, 34, 3, 1);
    ZX_ASSERT(wide_circle_matches(0, 0));
    xorcircle(40, 34, 3, 1);
    ZX_ASSERT(wide_circle_matches(1, 0));
    xorcircle(40, 34, 3, 1);
    ZX_ASSERT(wide_circle_matches(0, 0));

    circle(72, 36, 9, 1);
    fillb(92, 24, 25, 25);
    uncircle(104, 36, 9, 1);
    ZX_ASSERT(point(104, 27) == 0 && point(104, 36) == 1);
}

static void check_boxes_and_cursor(void) {
    int x, y;
    drawb(32, 56, 29, 23);
    ZX_ASSERT(point(32, 68) == 1 && point(44, 68) == 0);
    xorclga(38, 61, 54, 73);
    for (y = 60; y <= 74; ++y)
        for (x = 37; x <= 55; ++x)
            ZX_ASSERT(point(x, y) == (x >= 38 && x <= 54 && y >= 61 && y <= 73));
    xorclga(38, 61, 54, 73);
    ZX_ASSERT(point(44, 68) == 0 && point(32, 68) == 1);

    draw(72, 56, 96, 56);
    ZX_ASSERT(point(84, 56) == 1);
    undraw(72, 56, 96, 56);
    ZX_ASSERT(point(84, 56) == 0);

    /* XOR and erase continue to draw and advance the cursor with the pen up. */
    pen_up();
    setpos(72, 62);
    move(0, 6);
    ZX_ASSERT(getx() == 72 && gety() == 68 && point(72, 65) == 0);
    xordrawto(100, 68);
    ZX_ASSERT(getx() == 100 && gety() == 68 && point(84, 68) == 1);
    xordrawr(0, 16);
    ZX_ASSERT(getx() == 100 && gety() == 84 && point(100, 76) == 1);
    undrawr(0, -16);
    ZX_ASSERT(getx() == 100 && gety() == 68 && point(100, 76) == 0);
    undrawto(72, 68);
    ZX_ASSERT(getx() == 72 && gety() == 68 && point(84, 68) == 0);
    xordrawto(100, 68);
    xordrawr(0, 16);
    pen_down();
}

static void check_mode(bc_video_mode_t mode, const char *tag, int right, int bottom) {
    zx_status_t status = bc_set_video_mode(mode);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_step_marker(tag);
        return;
    }
    zx_set_ink(6);
    clg();
    ZX_ASSERT(getmaxx() == right && getmaxy() == bottom);
    check_pixels(right, bottom);
    check_wide_circles();
    check_boxes_and_cursor();
    zx_test_step_shot(tag);
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        check_mode(BC_VIDEO_ZX_256, "zx256", 255, 191);
        check_mode(BC_VIDEO_ATM_320, "atm320", 319, 199);
    }
    zx_test_finish();
    return 0;
}
