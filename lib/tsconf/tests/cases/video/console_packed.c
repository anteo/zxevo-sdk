#include <stdio.h>
#include <string.h>
#include <tsconf.h>
#include <zx_test.h>

#define SCREEN_BASE 0xc000u
static volatile uint8_t *const screen = (volatile uint8_t *)SCREEN_BASE;
extern const uint8_t font_8x8_zx_system[96][8];

static void check_packed16(void) {
    const ts_surface_t canvas = {TS_VIDEO_16C | TS_VIDEO_320X200, 0x50, NULL};
    const uint8_t *glyph = zx_font5_data['A' - 32];
    zx_console_size_t grid;
    uint8_t row, x;

    ts_memory_set_page3(0x7e);
    screen[0] = 0x69;
    ZX_ASSERT(ts_video_select_draw_surface(&canvas) == ZX_OK);
    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK && zx_console_get_font() == &zx_font5);
    ZX_ASSERT(zx_console_get_size(&grid) == ZX_OK && grid.columns == 53 && grid.rows == 25);
    zx_set_ink(0xfa);
    zx_set_paper(0xf3);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(52, 24) == ZX_OK && zx_console_gotoxy(53, 24) != ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(1, 8) == ZX_OK);
    printf("%c", 'A');
    zx_set_paper(5);
    ZX_ASSERT(zx_console_draw_op(1, 9, "A", ZX_TEXT_TRANSPARENT) == ZX_OK);
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && screen[0] == 0x69);
    ts_memory_set_page3(0x57);
    ZX_ASSERT(screen[0x3fff] == 0x33);
    ts_memory_set_page3(0x51);
    for (row = 0; row < 8; ++row) {
        uint16_t offset = 256u * row + 3;
        for (x = 0; x < 5; ++x) {
            uint8_t pair = screen[offset + (x >> 1)];
            uint8_t pixel = (x & 1) ? pair & 15 : pair >> 4;
            ZX_ASSERT(pixel == ((glyph[row] & (0x80u >> x)) ? 10 : 3));
        }
        ZX_ASSERT(screen[offset - 1] == 0x33 && (screen[offset + 2] & 15) == 3);
        ZX_ASSERT(
            !memcmp((const void *)(screen + offset), (const void *)(screen + offset + 0x800), 3));
    }
}

static void check_packed256(void) {
    const ts_surface_t canvas = {TS_VIDEO_256C | TS_VIDEO_320X240, 0x40, NULL};
    uint8_t row, x;

    ts_memory_set_page3(0x7e);
    zx_set_ink(0xa5);
    zx_set_paper(0xb7);
    ZX_ASSERT(ts_video_select_draw_surface(&canvas) == ZX_OK);
    ZX_ASSERT(zx_console_set_font(&zx_font8) == ZX_OK);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(32, 4) == ZX_OK && zx_console_gotoxy(40, 4) != ZX_OK);
    zx_set_paper(0xb6);
    ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_TRANSPARENT) == ZX_OK);
    ZX_ASSERT(zx_console_puts("Z") == ZX_OK);
    ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_OPAQUE) == ZX_OK);
    zx_set_paper(0xb7);
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && screen[0] == 0x69);
    ts_memory_set_page3(0x4f);
    ZX_ASSERT(screen[0x3fff] == 0xb7);
    ts_memory_set_page3(0x41);
    for (row = 0; row < 8; ++row) {
        uint16_t offset = 512u * row + 256;
        for (x = 0; x < 8; ++x) {
            uint8_t bits = font_8x8_zx_system['Z' - 32][row];
            ZX_ASSERT(screen[offset + x] == ((bits & (0x80u >> x)) ? 0xa5 : 0xb7));
        }
    }
}

static void check_font_callback(uint16_t x, uint16_t y, const zx_font_t *font, uint8_t code,
                                uint8_t ink, uint8_t paper, zx_text_bg_t background) {
    ZX_ASSERT(x == 18 && y == 16 && font->advance == 6);
    ZX_ASSERT(code == 'Z' && ink == 0xa5 && paper == 0xb7);
    ZX_ASSERT(background == ZX_TEXT_TRANSPARENT);
}

static void check_custom_font(void) {
    const zx_font_t custom = {&font_8x8_zx_system[0][0], 5, 8, 6, 0, check_font_callback};

    ZX_ASSERT(zx_console_set_font(NULL) != ZX_OK);
    ZX_ASSERT(zx_console_set_font(&custom) == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(3, 2) == ZX_OK);
    ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_TRANSPARENT) == ZX_OK);
    ZX_ASSERT(zx_console_putc('Z') == ZX_OK);
    ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(zx_console_set_font(&zx_font8) == ZX_OK);
}

int main(void) {
    zx_test_init();
    check_packed16();
    zx_test_step_marker("16c-console");
    check_packed256();
    check_custom_font();
    zx_test_step_marker("256c-console");
    zx_test_finish();
    return 0;
}
