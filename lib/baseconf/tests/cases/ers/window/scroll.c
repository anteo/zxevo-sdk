#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

enum { WINDOW_X = 7, WINDOW_Y = 7, WINDOW_WIDTH = 18, ROWS = 5, GLYPH_HEIGHT = 8 };

static bc_ers_window_t window = {
    .x = WINDOW_X,
    .y = WINDOW_Y,
    .height = ROWS + 2,
    .width = WINDOW_WIDTH,
    .attribute = 0x47,
    .flags = BC_ERS_WINDOW_NO_TEXT,
};
/* Position at x=69 pixels, row 8. Tab two characters after each newline. */
static const char lines[] = "\x16\x08\x45\x17\xff"
                            "First"
                            "\x0d\x09\x02"
                            "Second"
                            "\x0d\x09\x02"
                            "Third"
                            "\x0d\x09\x02"
                            "Fourth"
                            "\x0d\x09\x02"
                            "Fifth";
static const uint8_t row_colors[ROWS] = {0x4f, 0x57, 0x5f, 0x60, 0x68};
static uint8_t original[ROWS][GLYPH_HEIGHT][WINDOW_WIDTH];

static uint8_t *bitmap_row(uint8_t row, uint8_t scanline) {
    uint8_t y = WINDOW_Y + 1 + row;
    uint16_t address = 0x4000u | ((uint16_t)(y & 0x18) << 8) | ((uint16_t)scanline << 8) |
                       ((uint16_t)(y & 7) << 5);
    return (uint8_t *)(address + WINDOW_X);
}

static uint8_t *attribute_row(uint8_t row) {
    return (uint8_t *)(0x5800u + (WINDOW_Y + 1 + row) * 32u + WINDOW_X);
}

static void check_row(uint8_t row, uint8_t bitmap_source, uint8_t color_source) {
    uint8_t scanline;
    uint8_t column;
    const uint8_t *attributes = attribute_row(row);

    for (scanline = 0; scanline < GLYPH_HEIGHT; ++scanline) {
        ZX_ASSERT(memcmp(bitmap_row(row, scanline), original[bitmap_source][scanline],
                         WINDOW_WIDTH) == 0);
    }
    for (column = 1; column < WINDOW_WIDTH - 1; ++column) {
        ZX_ASSERT(attributes[column] == row_colors[color_source]);
    }
}

static void check_scroll(void) {
    zx_status_t status;
    uint8_t row;
    uint8_t scanline;

    status = bc_set_video_mode(BC_VIDEO_ZX_256);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    status = bc_select_screen(ZX_SCREEN_0);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    memset((void *)0x4000u, 0, 6912u);

    status = bc_ers_draw_window(&window);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(bc_ers_print_message(&window, lines) == ZX_OK);
    for (row = 0; row < ROWS; ++row) {
        memset(attribute_row(row) + 1, row_colors[row], WINDOW_WIDTH - 2);
        for (scanline = 0; scanline < GLYPH_HEIGHT; ++scanline) {
            memcpy(original[row][scanline], bitmap_row(row, scanline), WINDOW_WIDTH);
        }
        if (row != 0) {
            ZX_ASSERT(memcmp(original[row], original[row - 1], sizeof(original[0])) != 0);
        }
    }
    zx_test_step_shot("before");

    /* The ROM copies within the interior and leaves the vacated row intact. */
    ZX_ASSERT(bc_ers_scroll_up(&window, 0) == ZX_OK);
    for (row = 0; row < ROWS - 1; ++row) check_row(row, row + 1, row);
    check_row(ROWS - 1, ROWS - 1, ROWS - 1);
    zx_test_step_shot("up_bitmap_only");

    ZX_ASSERT(bc_ers_scroll_down(&window, 1) == ZX_OK);
    check_row(0, 1, 0);
    for (row = 1; row < ROWS; ++row) check_row(row, row, row - 1);
    zx_test_step_shot("down_with_attributes");

    ZX_ASSERT(bc_ers_scroll_up(&window, 1) == ZX_OK);
    for (row = 0; row < ROWS - 1; ++row) check_row(row, row + 1, row);
    check_row(ROWS - 1, ROWS - 1, ROWS - 2);
    zx_test_step_marker("up_with_attributes");

    ZX_ASSERT(bc_ers_scroll_down(&window, 0) == ZX_OK);
    check_row(0, 1, 0);
    for (row = 1; row < ROWS - 1; ++row) check_row(row, row, row);
    check_row(ROWS - 1, ROWS - 1, ROWS - 2);
    zx_test_step_marker("down_bitmap_only");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_ers_set_profile(BC_ERS_SERVICES_ROM);
        check_scroll();
    }
    zx_test_finish();
    return 0;
}
