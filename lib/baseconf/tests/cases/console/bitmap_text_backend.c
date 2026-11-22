#include <zx/console.h>
#include <baseconf/font.h>
#include <zx/graphics.h>
#include <zx/printf.h>
#include <baseconf/text.h>
#include <baseconf/video.h>

#include "bc_case.h"

extern uint8_t _console_x, _console_y;

/* Second scanline of cell (3, 2) in both ZX bitmap layouts. */
static volatile uint8_t *const cell_scanline = (volatile uint8_t *)0xc143u;
static uint8_t custom_draws;

static void custom_draw(uint16_t x, uint16_t y, const zx_font_t *font, uint8_t code, uint8_t ink,
                        uint8_t paper, zx_text_bg_t background) {
    (void)x;
    (void)y;
    (void)font;
    (void)code;
    (void)ink;
    (void)paper;
    ZX_ASSERT(background == (custom_draws == 0 ? ZX_TEXT_OPAQUE : ZX_TEXT_TRANSPARENT));
    ++custom_draws;
}

static const zx_font_t custom_font = {&zx_font5_data[0][0], 5, 8, 6, 0, custom_draw};

/* Bottom character row in W3. Columns 38..41 exercise all four alignments,
 * including a glyph spilling into the last byte of the screen. */
static void check_multicolor_font5(uint8_t ink) {
    const uint8_t *glyph = zx_font5_data['p' - 32];
    uint8_t column, row;
    zx_set_ink(ink);
    zx_set_paper(1);
    for (column = 38; column <= 41; ++column) {
        uint8_t x = column * 6;
        uint8_t shift = x & 7;
        uint16_t mask = 0xf800u >> shift;
        volatile uint8_t *first = (volatile uint8_t *)(0xd0e0u + (x >> 3));
        for (row = 0; row < 8; ++row) {
            volatile uint8_t *p = first + 256u * row;
            p[0] = 0xa5;
            p[1] = 0x5a;
            p[0x2000] = p[0x2001] = 0x96;
        }
        ZX_ASSERT(zx_console_draw_op(column, 23, "p", ZX_TEXT_OPAQUE) == ZX_OK);
        for (row = 0; row < 8; ++row) {
            volatile uint8_t *p = first + 256u * row;
            uint16_t bits = ink == 1 ? 0 : (uint16_t)glyph[row] << 8;
            uint16_t expected = (0xa55au & ~mask) | ((bits >> shift) & mask);
            uint8_t attr = ink == 1 ? 0x09 : 0x4a;
            ZX_ASSERT(p[0] == (uint8_t)(expected >> 8) && p[1] == (uint8_t)expected);
            ZX_ASSERT(p[0x2000] == attr && p[0x2001] == (shift >= 4 ? attr : 0x96));
        }
    }
}

static void check_missing_backend(void) {
    uint8_t bitmap = *cell_scanline;
    ZX_ASSERT(zx_console_gotoxy(3, 2) == ZX_OK);
    ZX_ASSERT(zx_console_putc('A') == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_putc('\t') == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_draw(3, 2, "A") == ZX_UNSUPPORTED);
    ZX_ASSERT(bc_text_draw_font(3, 2, "A", &zx_font5_data[0][0]) == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_printf("A") == -1);
    ZX_ASSERT(zx_console_printf("ABCD") == -1);
    ZX_ASSERT(_console_x == 3 && _console_y == 2);
    ZX_ASSERT(*cell_scanline == bitmap);
}

/* Row zero's attribute doubles as the next source row in a RAM font. */
static void check_multicolor_ram_font(void) {
    zx_font_t font = zx_font5;
    volatile uint8_t *const bitmap = (volatile uint8_t *)0xc000;
    volatile uint8_t *const glyph = bitmap + 0x1fff;
    font.glyphs = (const uint8_t *)glyph;
    glyph[0] = glyph[1] = bitmap[0x100] = 0;
    zx_set_ink(10);
    zx_set_paper(1);
    ZX_ASSERT(zx_console_set_font(&font) == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(0, 0, " ", ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
    ZX_ASSERT(glyph[1] == 0x4a && bitmap[0x100] == (0x4a & 0xf8));
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, 5) == ZX_OK);
        ZX_ASSERT(zx_graphics_begin() == ZX_OK);
        ZX_ASSERT(zx_graphics_end() == ZX_OK);
        ZX_ASSERT(zx_console_get_font() == &zx_font8);
        *cell_scanline = 0x69;
        check_missing_backend();
        zx_test_step_marker("initial_surface");

        ZX_ASSERT(zx_set_draw_buffer(BC_VIDEO_ZX_MULTICOLOR, 5, ZX_WINDOW_3) == ZX_OK);
        ZX_ASSERT(zx_console_putc('A') == ZX_OK);
        ZX_ASSERT(_console_x == 4 && _console_y == 2);
        ZX_ASSERT(bc_text_draw_font(3, 2, "A", &zx_font5_data[0][0]) == ZX_OK);
        ZX_ASSERT(*cell_scanline == zx_font5_data['A' - 32][1]);
        *cell_scanline = 1;
        cell_scanline[0x2000] = 0x2e;
        ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_TRANSPARENT) == ZX_OK);
        ZX_ASSERT(bc_text_draw_font(3, 2, "A", &zx_font5_data[0][0]) == ZX_OK);
        ZX_ASSERT(*cell_scanline == (zx_font5_data['A' - 32][1] | 1));
        ZX_ASSERT(cell_scanline[0x2000] == 0x2e);
        ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_OPAQUE) == ZX_OK);
        ZX_ASSERT(zx_set_draw_buffer(BC_VIDEO_ZX_256, 5, ZX_WINDOW_3) == ZX_OK);
        check_missing_backend();
        zx_test_step_marker("surface_changes");

        ZX_ASSERT(zx_console_set_font(&custom_font) == ZX_OK);
        ZX_ASSERT(zx_console_putc('C') == ZX_OK && custom_draws == 1);
        ZX_ASSERT(zx_console_draw_op(0, 1, "ABCD\nE", ZX_TEXT_TRANSPARENT) == ZX_OK &&
                  custom_draws == 5);
        ZX_ASSERT(bc_text_draw_font(3, 2, "A", &zx_font5_data[0][0]) == ZX_UNSUPPORTED);
        ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
        check_missing_backend();
        zx_test_step_marker("font_changes");

        ZX_ASSERT(zx_set_draw_buffer(BC_VIDEO_ZX_MULTICOLOR, 5, ZX_WINDOW_3) == ZX_OK);
        check_multicolor_font5(10);
        check_multicolor_font5(1);
        check_multicolor_ram_font();
        zx_test_step_marker("multicolor_font5");
    }
    zx_test_finish();
    return 0;
}
