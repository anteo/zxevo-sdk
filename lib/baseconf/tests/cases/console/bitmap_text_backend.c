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

int main(void) {
    const bc_surface_t zx = {BC_VIDEO_ZX_256, 5, 5};
    const bc_surface_t multicolor = {BC_VIDEO_ZX_MULTICOLOR, 5, 5};

    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, zx.page0) == ZX_OK);
        ZX_ASSERT(zx_graphics_begin() == ZX_OK);
        ZX_ASSERT(zx_graphics_end() == ZX_OK);
        ZX_ASSERT(zx_console_get_font() == &zx_font8);
        *cell_scanline = 0x69;
        check_missing_backend();
        zx_test_step_marker("initial_surface");

        ZX_ASSERT(bc_select_draw_surface(&multicolor) == ZX_OK);
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
        ZX_ASSERT(bc_select_draw_surface(&zx) == ZX_OK);
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
    }
    zx_test_finish();
    return 0;
}
