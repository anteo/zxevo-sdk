#include <baseconf.h>
#include <baseconf/video.h>
#include <graphics.h>
#include <zx/console.h>
#include <zx/graphics.h>

#include "bc_case.h"

enum { INK = 6, CLEAR_PAPER = 4 };

static uint8_t areas_match(uint8_t cleared) {
    uint16_t x, y;
    uint8_t index;
    for (y = 47; y <= 76; ++y) {
        for (x = 0; x <= 172; ++x) {
            uint8_t expected = 0;
            if (y >= 48 && y <= 75 && (x <= 25 || (x >= 58 && x <= 97) || (x >= 132 && x <= 171)))
                expected = INK;
            if (x >= 70 && x <= 85 && y >= 56 && y <= 67) expected = cleared;
            if (x >= 141 && x <= 162 && y >= 54 && y <= 69 &&
                (x == 141 || x == 162 || y == 54 || y == 69))
                expected = cleared;
            if (zx_read_pixel_index(x, y, &index) != ZX_OK || index != expected) return 0;
        }
    }
    return 1;
}

static void check_mode(bc_video_mode_t mode, const char *tag, uint8_t cleared) {
    zx_status_t status = bc_set_video_mode(mode);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        zx_test_step_marker(tag);
        return;
    }
    zx_set_paper(0);
    zx_set_ink(INK);
    clg();

    /* A clipped fill, an interior cutout, and an erased frame. */
    fillb(-5, 48, 31, 28);
    fillb(32, 48, 0, 28);
    fillb(40, 48, 12, 0);
    fillb(58, 48, 40, 28);
    fillb(132, 48, 40, 28);
    zx_set_paper(CLEAR_PAPER);
    clga(85, 67, 70, 56);
    undrawb(141, 54, 22, 16);

    ZX_ASSERT(areas_match(cleared));
    zx_test_step_shot(tag);
}

static void check_atm_full_width(void) {
    uint16_t x;
    uint8_t index;

    /* Clipping leaves exactly one complete scanline at the bottom. */
    fillb(-4, 199, 324, 3);
    for (x = 0; x < 320; ++x) {
        ZX_ASSERT(zx_read_pixel_index(x, 199, &index) == ZX_OK && index == INK);
    }
    zx_draw_clear_rect(0, 199, 320, 1);
    for (x = 0; x < 320; ++x) {
        ZX_ASSERT(zx_read_pixel_index(x, 199, &index) == ZX_OK && index == CLEAR_PAPER);
        ZX_ASSERT(zx_read_pixel_index(x, 198, &index) == ZX_OK && index == 0);
    }
}

static void check_packed_transparency(void) {
    const uint8_t *glyph = zx_font8.glyphs + ('A' - 32) * 8;
    uint8_t x, y, color;

    ZX_ASSERT(zx_console_set_font(&zx_font8) == ZX_OK);
    zx_set_paper(3);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    zx_set_ink(14);
    zx_set_paper(5);
    ZX_ASSERT(zx_console_draw_op(0, 0, "A", ZX_TEXT_TRANSPARENT) == ZX_OK);
    ZX_ASSERT(zx_console_draw(1, 0, "A") == ZX_OK);
    for (y = 0; y < 8; ++y) {
        for (x = 0; x < 8; ++x) {
            uint8_t marked = glyph[y] & (0x80u >> x);
            ZX_ASSERT(zx_read_pixel_index(x, y, &color) == ZX_OK && color == (marked ? 14 : 3));
            ZX_ASSERT(zx_read_pixel_index(x + 8, y, &color) == ZX_OK && color == (marked ? 14 : 5));
        }
    }

    glyph = zx_font5_data['A' - 32];
    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
    zx_set_paper(3);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    zx_set_paper(5);
    ZX_ASSERT(zx_console_draw_op(0, 0, "AAAA", ZX_TEXT_TRANSPARENT) == ZX_OK);
    ZX_ASSERT(zx_console_draw(0, 1, "AAAA") == ZX_OK);
    /* A six-pixel advance exercises all four pair alignments and leaves a gap. */
    for (y = 0; y < 8; ++y) {
        for (x = 0; x < 24; ++x) {
            uint8_t column = x % 6;
            uint8_t marked = column < 5 && (glyph[y] & (0x80u >> column));
            ZX_ASSERT(zx_read_pixel_index(x, y, &color) == ZX_OK && color == (marked ? 14 : 3));
            ZX_ASSERT(zx_read_pixel_index(x, y + 8, &color) == ZX_OK &&
                      color == (marked ? 14 : (column < 5 ? 5 : 3)));
        }
    }
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        check_mode(BC_VIDEO_ZX_256, "zx256", 0);
        check_mode(BC_VIDEO_ATM_320, "atm320", CLEAR_PAPER);
        check_atm_full_width();
        zx_test_step_marker("atm320_full_width");
        check_packed_transparency();
        zx_test_step_marker("atm320_packed_text");
    }
    zx_test_finish();
    return 0;
}
