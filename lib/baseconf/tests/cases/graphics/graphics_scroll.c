#include <baseconf.h>
#include <zx/graphics.h>
#include <baseconf/video.h>
#include <graphics.h>

#include "bc_case.h"

/* Legacy graphics entry points are not declared by graphics.h. */
void lscroll_1px(void);
void lscroll_2px(void);
void lscroll_4px(void);
void lscroll_8px(void);
void rscroll_1px(void);
void rscroll_2px(void);
void rscroll_4px(void);
void rscroll_8px(void);
void scrollup_1px(void);
void scrollup_4px(void);
void scrollup_6px(void);

typedef void (*scroll_fn)(void);

typedef struct {
    scroll_fn function;
    uint8_t pixels;
} scroll_case_t;

static const scroll_case_t left_scrolls[] = {
    {lscroll_1px, 1},
    {lscroll_2px, 2},
    {lscroll_4px, 4},
    {lscroll_8px, 8},
};
static const scroll_case_t right_scrolls[] = {
    {rscroll_1px, 1},
    {rscroll_2px, 2},
    {rscroll_4px, 4},
    {rscroll_8px, 8},
};
static const scroll_case_t upward_scrolls[] = {
    {scrollup_1px, 1},
    {scrollup_4px, 4},
    {scrollup_6px, 6},
};

enum { INITIAL_PAPER = 1, SCROLL_PAPER = 4, SCROLL_INK = 7 };

static void clear_for_scroll(void) {
    zx_set_paper(INITIAL_PAPER);
    zx_set_ink(SCROLL_INK);
    clg();
}

static uint8_t check_horizontal_edge(const scroll_case_t *test, int width, uint8_t right,
                                     uint8_t new_paper) {
    int distance;
    int edge = right ? width - 1 : 0;
    int opposite = width - 1 - edge;
    uint8_t index;

    clear_for_scroll();
    cplot(edge, 16, SCROLL_INK);
    cplot(right ? edge - test->pixels : test->pixels, 16, SCROLL_INK);
    cplot(opposite, 16, SCROLL_INK);
    zx_set_paper(SCROLL_PAPER);
    test->function();

    /* Measured from the discarded edge. One dot disappears, one reaches
     * that edge, and the far dot stops just before the newly exposed strip. */
    for (distance = 0; distance < width; ++distance) {
        int x = right ? edge - distance : distance;
        uint8_t expected = INITIAL_PAPER;
        if (distance == 0 || distance == width - 1 - test->pixels) expected = SCROLL_INK;
        if (distance >= width - test->pixels) expected = new_paper;
        if (zx_read_pixel_index(x, 16, &index) != ZX_OK || index != expected) return 0;
    }
    return 1;
}

static uint8_t check_upward_edge(const scroll_case_t *test, int height, uint8_t new_paper) {
    int y;
    uint8_t index;
    clear_for_scroll();
    cplot(16, 0, SCROLL_INK);
    cplot(16, test->pixels, SCROLL_INK);
    cplot(16, height - 1, SCROLL_INK);
    zx_set_paper(SCROLL_PAPER);
    test->function();

    for (y = 0; y < height; ++y) {
        uint8_t expected = INITIAL_PAPER;
        if (y == 0 || y == height - 1 - test->pixels) expected = SCROLL_INK;
        if (y >= height - test->pixels) expected = new_paper;
        if (zx_read_pixel_index(16, y, &index) != ZX_OK || index != expected) return 0;
    }
    return 1;
}

static void check_edges(bc_video_mode_t mode, const char *tag) {
    uint8_t i;
    int width, height;
    zx_video_size_t size = {0, 0};
    uint8_t packed = mode == BC_VIDEO_PENTAGON_256 || mode == BC_VIDEO_ATM_320;
    uint8_t up_paper = mode == BC_VIDEO_ZX_256 ? INITIAL_PAPER : SCROLL_PAPER;
    zx_status_t status = bc_set_video_mode(mode);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK);
        width = (int)size.width;
        height = (int)size.height;
        for (i = 0; i < sizeof(left_scrolls) / sizeof(left_scrolls[0]); ++i) {
            /* Whole-byte moves update bitmap attributes. Smaller bitmap
             * moves keep the destination attributes; packed moves use paper. */
            uint8_t paper = packed || left_scrolls[i].pixels == 8 ? SCROLL_PAPER : INITIAL_PAPER;
            ZX_ASSERT(check_horizontal_edge(&left_scrolls[i], width, 0, paper));
            ZX_ASSERT(check_horizontal_edge(&right_scrolls[i], width, 1, paper));
        }
        for (i = 0; i < sizeof(upward_scrolls) / sizeof(upward_scrolls[0]); ++i)
            ZX_ASSERT(check_upward_edge(&upward_scrolls[i], height, up_paper));
    }
    zx_test_step_marker(tag);
}

static void show_shift(bc_video_mode_t mode, const char *tag, const scroll_case_t *test,
                       uint8_t direction) {
    int width, height, x, y, target_x, target_y;
    zx_video_size_t size = {0, 0};
    if (bc_set_video_mode(mode) != ZX_OK) {
        zx_test_step_skip(tag, "video mode unavailable");
        return;
    }
    zx_set_paper(0);
    zx_set_ink(7);
    ZX_ASSERT(zx_graphics_get_size(&size) == ZX_OK);
    width = (int)size.width;
    height = (int)size.height;
    x = width >> 1;
    y = height >> 1;
    if (direction == 2) y += 6;
    target_x = direction == 0 ? x - test->pixels : direction == 1 ? x + test->pixels : x;
    target_y = direction == 2 ? y - test->pixels : y;

    clg();
    cplot(x, y, 7);
    test->function();

    /* The fixed cross marks the original coordinate; the circle marks the
       expected coordinate after scrolling. The moved pixel should sit inside. */
    zx_set_ink(9);
    zx_draw_hline_op(x - 2, x + 2, y, ZX_DRAW_SET);
    zx_draw_vline_op(x, y - 2, y + 2, ZX_DRAW_SET);
    zx_set_ink(14);
    zx_draw_circle_op(target_x, target_y, 5, ZX_DRAW_SET);
    zx_test_step_shot(tag);
}

static void show_mode(bc_video_mode_t mode, uint8_t all_variants) {
    uint8_t i;
    if (all_variants) {
        static const char *left_tags[] = {"zx256_l1", "zx256_l2", "zx256_l4", "zx256_l8"};
        static const char *right_tags[] = {"zx256_r1", "zx256_r2", "zx256_r4", "zx256_r8"};
        static const char *up_tags[] = {"zx256_u1", "zx256_u4", "zx256_u6"};
        for (i = 0; i < 4; ++i) show_shift(mode, left_tags[i], &left_scrolls[i], 0);
        for (i = 0; i < 4; ++i) show_shift(mode, right_tags[i], &right_scrolls[i], 1);
        for (i = 0; i < 3; ++i) show_shift(mode, up_tags[i], &upward_scrolls[i], 2);
    } else {
        const char *left_tag, *right_tag, *up_tag;
        switch (mode) {
        case BC_VIDEO_ZX_MULTICOLOR:
            left_tag = "multi_l8";
            right_tag = "multi_r4";
            up_tag = "multi_u6";
            break;
        case BC_VIDEO_PENTAGON_256:
            left_tag = "pent_l8";
            right_tag = "pent_r4";
            up_tag = "pent_u6";
            break;
        case BC_VIDEO_ATM_320:
            left_tag = "atm320_l8";
            right_tag = "atm320_r4";
            up_tag = "atm320_u6";
            break;
        default:
            left_tag = "atm640_l8";
            right_tag = "atm640_r4";
            up_tag = "atm640_u6";
            break;
        }
        show_shift(mode, left_tag, &left_scrolls[3], 0);
        show_shift(mode, right_tag, &right_scrolls[2], 1);
        show_shift(mode, up_tag, &upward_scrolls[2], 2);
    }
}

int main(void) {
    if (bc_case_init() != ZX_OK) {
        zx_test_finish();
        return 0;
    }

    ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
    show_mode(BC_VIDEO_ZX_256, 1);
    show_mode(BC_VIDEO_ZX_MULTICOLOR, 0);
    show_mode(BC_VIDEO_PENTAGON_256, 0);
    show_mode(BC_VIDEO_ATM_320, 0);
    show_mode(BC_VIDEO_ATM_640, 0);
    check_edges(BC_VIDEO_ZX_256, "zx256_edges");
    check_edges(BC_VIDEO_ZX_MULTICOLOR, "multi_edges");
    check_edges(BC_VIDEO_PENTAGON_256, "pent_edges");
    check_edges(BC_VIDEO_ATM_320, "atm320_edges");
    check_edges(BC_VIDEO_ATM_640, "atm640_edges");
    zx_test_finish();
    return 0;
}
