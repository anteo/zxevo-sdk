#include <baseconf.h>
#include <zx/graphics.h>
#include <baseconf/video.h>
#include <graphics.h>

#include "bc_case.h"

enum {
    WIDTH = 16,
    HEIGHT = 8,
    LEFT = 16,
    SPACING = 48,
    XOR_TOP = 60,
    CLEAR_TOP = 124,
    INITIAL_INK = 2,
    INITIAL_PAPER = 1,
    DRAW_INK = 13,
    DRAW_PAPER = 12
};

typedef struct {
    void (*primitive)(int x, int y, zx_draw_op_t operation);
    const char *pixels;
} draw_case_t;

static void draw_horizontal(int x, int y, zx_draw_op_t operation) {
    zx_draw_hline_op(x + 3, x + 12, y + 3, operation);
}

static void draw_vertical(int x, int y, zx_draw_op_t operation) {
    zx_draw_vline_op(x + 6, y + 1, y + 6, operation);
}

static void draw_diagonal(int x, int y, zx_draw_op_t operation) {
    zx_draw_line_op(x + 3, y + 1, x + 8, y + 6, operation);
}

static void draw_circle(int x, int y, zx_draw_op_t operation) {
    zx_draw_circle_op(x + 7, y + 3, 3, operation);
}

static void draw_ellipse(int x, int y, zx_draw_op_t operation) {
    zx_draw_ellipse_op(x + 7, y + 3, 2, 1, operation);
}

/* '#' changes under either operation. '+' is erased by CLEAR but survives
 * XOR because the outline emits that point twice. '.' stays filled.
 * The vertical and diagonal lines cross a ZX screen-third boundary in both rows. */
static const draw_case_t draw_cases[] = {
    {draw_horizontal, "................"
                      "................"
                      "................"
                      "...##########..."
                      "................"
                      "................"
                      "................"
                      "................"},
    {draw_vertical, "................"
                    "......#........."
                    "......#........."
                    "......#........."
                    "......#........."
                    "......#........."
                    "......#........."
                    "................"},
    {draw_diagonal, "................"
                    "...#............"
                    "....#..........."
                    ".....#.........."
                    "......#........."
                    ".......#........"
                    "........#......."
                    "................"},
    {draw_circle, "......#+#......."
                  ".....+...+......"
                  "....#.....#....."
                  "....+.....+....."
                  "....#.....#....."
                  ".....+...+......"
                  "......#+#......."
                  "................"},
    {draw_ellipse, "................"
                   "................"
                   "......#+#......."
                   ".....+...+......"
                   "......#+#......."
                   "................"
                   "................"
                   "................"},
};

static void fill_pixels(int left, int top) {
    int x, y;
    for (y = top; y < top + HEIGHT; ++y)
        for (x = left; x < left + WIDTH; ++x) cplot(x, y, INITIAL_INK);
}

static uint8_t pixels_match(uint16_t left, uint16_t top, const char *pixels, uint8_t outline,
                            uint8_t coincident) {
    uint16_t x, y;
    uint8_t index;
    for (y = top; y < top + HEIGHT; ++y) {
        for (x = left; x < left + WIDTH; ++x, ++pixels) {
            uint8_t expected = INITIAL_INK;
            if (*pixels == '#') expected = outline;
            if (*pixels == '+') expected = coincident;
            if (zx_read_pixel_index(x, y, &index) != ZX_OK || index != expected) return 0;
        }
    }
    return 1;
}

static void check_mode(bc_video_mode_t mode, const char *name) {
    uint8_t i;
    int left;
    zx_status_t status = bc_set_video_mode(mode);
    uint8_t packed = mode == BC_VIDEO_PENTAGON_256 || mode == BC_VIDEO_ATM_320;
    uint8_t toggled = packed ? INITIAL_INK ^ DRAW_INK : INITIAL_PAPER;
    uint8_t cleared = packed ? DRAW_PAPER : INITIAL_PAPER;
    if (status != ZX_OK) {
        ZX_ASSERT(status == ZX_OK);
        zx_test_step_marker(name);
        return;
    }

    zx_set_paper(0);
    zx_set_ink(INITIAL_INK);
    clg();
    zx_set_paper(INITIAL_PAPER);
    for (i = 0, left = LEFT; i < sizeof(draw_cases) / sizeof(draw_cases[0]); ++i, left += SPACING) {
        fill_pixels(left, XOR_TOP);
        fill_pixels(left, CLEAR_TOP);
    }

    /* Bitmap operations preserve the stored attributes. Packed operations
     * must instead use the newly selected ink and paper. */
    zx_set_paper(DRAW_PAPER);
    zx_set_ink(DRAW_INK);
    for (i = 0, left = LEFT; i < sizeof(draw_cases) / sizeof(draw_cases[0]); ++i, left += SPACING) {
        const draw_case_t *test = &draw_cases[i];
        test->primitive(left, XOR_TOP, ZX_DRAW_XOR);
        ZX_ASSERT(pixels_match(left, XOR_TOP, test->pixels, toggled, INITIAL_INK));
        test->primitive(left, XOR_TOP, ZX_DRAW_XOR);
        ZX_ASSERT(pixels_match(left, XOR_TOP, test->pixels, INITIAL_INK, INITIAL_INK));
        /* Leave the toggled outline visible in the upper row. */
        test->primitive(left, XOR_TOP, ZX_DRAW_XOR);

        test->primitive(left, CLEAR_TOP, ZX_DRAW_CLEAR);
        ZX_ASSERT(pixels_match(left, CLEAR_TOP, test->pixels, cleared, cleared));
    }
    zx_test_step_shot(name);
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        check_mode(BC_VIDEO_ZX_256, "zx256");
        check_mode(BC_VIDEO_ZX_MULTICOLOR, "multicolor");
        check_mode(BC_VIDEO_PENTAGON_256, "pentagon256");
        check_mode(BC_VIDEO_ATM_320, "atm320");
        check_mode(BC_VIDEO_ATM_640, "atm640");
    }
    zx_test_finish();
    return 0;
}
