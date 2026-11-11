#include <stdio.h>
#include <string.h>
#include <tsconf.h>
#include <zx_test.h>

#define SCREEN_BASE 0xc000u
static volatile uint8_t *const screen = (volatile uint8_t *)SCREEN_BASE;
extern const uint8_t font_8x8_zx_system[96][8];
static const uint16_t palette[16] = {[1] = TS_PALETTE_RGB555(0, 0, 16),
                                     [10] = TS_PALETTE_RGB555(31, 0, 0),
                                     [14] = TS_PALETTE_RGB555(31, 31, 0)};

static void check_zx(void) {
    const uint8_t *narrow_a = zx_font5_data['A' - 32];
    uint8_t row;

    ts_memory_set_page3(0x60);
    memset((void *)screen, 0, 0x1b00);
    ts_video_set_page(0x60);
    ts_video_set_config(TS_VIDEO_ZX | TS_VIDEO_256X192 | TS_VIDEO_HIDE_TSU);
    ZX_ASSERT(ts_video_select_draw_screen(0x60, screen) == ZX_OK);
    ZX_ASSERT(zx_show_screen((zx_screen_t)2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_graphics_begin() == ZX_OK);
    ZX_ASSERT(zx_show_screen(ZX_SCREEN_1) == ZX_BUSY);
    ZX_ASSERT(zx_graphics_end() == ZX_OK);
    ZX_ASSERT(zx_show_screen(ZX_SCREEN_1) == ZX_OK && ts_memory_get_page3() == 0x60);
    ts_console_set_attribute(0x42);
    ZX_ASSERT(zx_console_gotoxy(3, 2) == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(32, 0) != ZX_OK);
    printf("A%d\n", 42);
    zx_console_putc('Z');
    for (row = 0; row < 8; ++row) {
        ZX_ASSERT(screen[0x43 + 256u * row] == font_8x8_zx_system['A' - 32][row]);
        ZX_ASSERT(screen[0x44 + 256u * row] == font_8x8_zx_system['4' - 32][row]);
        ZX_ASSERT(screen[0x45 + 256u * row] == font_8x8_zx_system['2' - 32][row]);
        ZX_ASSERT(screen[0x60 + 256u * row] == font_8x8_zx_system['Z' - 32][row]);
    }
    ZX_ASSERT(screen[0x1843] == 0x42 && screen[0x1845] == 0x42 && screen[0x1860] == 0x42);
    ZX_ASSERT(screen[0x1842] == 0 && screen[0x1846] == 0);
    ts_video_set_page(0x60);
    zx_test_step_shot("zx-printf");

    screen[0x1b00] = 0x69;
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    ZX_ASSERT(screen[0] == 0 && screen[0x17ff] == 0 && screen[0x1800] == 0x42 &&
              screen[0x1aff] == 0x42 && screen[0x1b00] == 0x69);

    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(1, 1) == ZX_OK);
    ts_console_set_attribute(0x47);
    zx_console_putc('A');
    for (row = 0; row < 8; ++row) {
        uint16_t offset = 0x20 + 256u * row;
        ZX_ASSERT(screen[offset] == narrow_a[row] >> 6);
        ZX_ASSERT(screen[offset + 1] == (uint8_t)(narrow_a[row] << 2));
    }
    ZX_ASSERT(screen[0x1820] == 0x47 && screen[0x1821] == 0x47);
    for (row = 0; row < 8; ++row) {
        screen[0x20 + 256u * row] = 0x80;
        screen[0x21 + 256u * row] = 0x01;
    }
    ts_console_set_attribute(0x46);
    ZX_ASSERT(zx_console_draw_op(1, 1, "A", ZX_TEXT_TRANSPARENT) == ZX_OK);
    for (row = 0; row < 8; ++row) {
        uint16_t offset = 0x20 + 256u * row;
        ZX_ASSERT(screen[offset] == (uint8_t)(0x80 | (narrow_a[row] >> 6)));
        ZX_ASSERT(screen[offset + 1] == (uint8_t)(1 | (narrow_a[row] << 2)));
    }
    ZX_ASSERT(screen[0x1820] == 0x47 && screen[0x1821] == 0x47);
    ts_console_set_attribute(0xc7);
    zx_set_ink(2);
    zx_set_paper(12);
    ZX_ASSERT(zx_console_gotoxy(0, 1) == ZX_OK);
    zx_console_putc('A');
    ZX_ASSERT(screen[0x1820] == 0xe2);
    ts_console_set_attribute(0x47);
    ZX_ASSERT(zx_console_set_font(&zx_font8) == ZX_OK);
}

static void check_text(void) {
    ts_memory_set_page3(0x71);
    memset((void *)screen, 0, 2048);
    ts_console_load_text_font(screen);
    ZX_ASSERT(!memcmp((const void *)(screen + 'A' * 8), font_8x8_zx_system['A' - 32], 8));
    ts_memory_set_page3(0x70);
    memset((void *)screen, 0, 0x4000);
    ZX_ASSERT(ts_video_set_mode(TS_VIDEO_TEXT | TS_VIDEO_320X240 | TS_VIDEO_HIDE_TSU, 0x70,
                                screen) == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(79, 29) == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(80, 29) != ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(79, 30) != ZX_OK);
    ts_console_set_attribute(0x1e);
    ZX_ASSERT(zx_console_gotoxy(78, 28) == ZX_OK);
    printf("A%d\n", 42);
    zx_console_putc('Z');
    ZX_ASSERT(screen[0x1c4e] == 'A' && screen[0x1c4f] == '4' && screen[0x1d00] == 'Z' &&
              screen[0x1d01] == 0);
    ZX_ASSERT(screen[0x1cce] == 0x1e && screen[0x1ccf] == 0x1e && screen[0x1d80] == 0x1e);
    ZX_ASSERT(zx_console_gotoxy(3, 2) == ZX_OK);
    ZX_ASSERT(zx_console_puts("TSConf text ") == ZX_OK);
    printf("%d", 42);
    ZX_ASSERT(screen[0x203] == 'T' && screen[0x210] == '2');
    zx_test_step_shot("native-text-printf");

    ZX_ASSERT(zx_console_draw_op(3, 2, "A", ZX_TEXT_TRANSPARENT) == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_TRANSPARENT) == ZX_OK);
    ZX_ASSERT(zx_console_putc('A') == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_puts("AB") == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_printf("AB") == -1);
    ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(screen[0x203] == 'T' && screen[0x283] == 0x1e);

    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    ZX_ASSERT(screen[0] == ' ' && screen[0x1d4f] == ' ' && screen[0x80] == 0x1e &&
              screen[0x1dcf] == 0x1e && screen[0x1d50] == 0 && screen[0x1dd0] == 0);
}

static void check_offscreen(void) {
    ts_surface_t surface = {TS_VIDEO_ZX, 0x61, screen};

    ts_memory_set_page3(0x61);
    memset((void *)screen, 0, 0x1b00);
    zx_set_ink(15);
    zx_set_paper(0);
    ZX_ASSERT(ts_video_select_draw_surface(&surface) == ZX_OK);
    surface.config = TS_VIDEO_TEXT;
    ts_video_set_config(TS_VIDEO_16C | TS_VIDEO_HIDE_GFX | TS_VIDEO_HIDE_TSU);
    ts_video_set_page(0x60);
    ZX_ASSERT(ts_video_select_draw_surface(NULL) != ZX_OK);
    ZX_ASSERT(ts_video_set_mode(TS_VIDEO_ZX, 0x61, screen + 1) != ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(32, 0) != ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(5, 0) == ZX_OK);
    ZX_ASSERT(zx_console_puts("\tZ") == ZX_OK);
    ZX_ASSERT(screen[0x1804] == 0 && screen[0x1805] == 0x47 && screen[0x1807] == 0x47 &&
              screen[0x1808] == 0x47 && screen[0x1809] == 0);
    ZX_ASSERT(screen[8] == font_8x8_zx_system['Z' - 32][0]);
}

int main(void) {
    zx_test_init();
    ZX_ASSERT(zx_console_clear() == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_console_putc('A') == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_console_puts("A") == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_console_puts("") == ZX_OK && zx_console_puts(NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_show_screen(ZX_SCREEN_0) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(ts_video_select_draw_screen(0x60, screen) == ZX_NOT_INITIALIZED);
    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_HIDE_TSU);
    ts_memory_set_page3(0x72);
    ts_fmaps_enable(SCREEN_BASE);
    ts_fmaps_write_words(TS_FMAPS_CRAM(SCREEN_BASE), palette, 16);
    ts_fmaps_disable();
    ts_video_set_border(0);
    ts_video_set_palette_select(0);
    ts_video_set_scroll(0, 0);
    check_zx();
    check_text();
    check_offscreen();
    zx_test_finish();
    return 0;
}
