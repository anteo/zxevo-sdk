#include <tsconf.h>
#include <zx_test.h>

static volatile uint8_t *const w3 = (volatile uint8_t *)0xc000;

static void check_text(void) {
    const ts_surface_t text = {TS_VIDEO_TEXT, 0x70, w3};

    ts_memory_set_page3(0x70);
    ZX_ASSERT(ts_video_select_draw_surface(&text) == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(4, 3) == ZX_OK);
    zx_set_colors(COLOR_BLUE, COLOR_YELLOW | COLOR_BRIGHT, COLOR_RED);
    w3[0x140] = 0x69;
    w3[0x201] = 0x69;
    ZX_ASSERT(zx_console_draw(62, 1, "BCD") == ZX_OK);
    ZX_ASSERT(zx_console_draw(0, 2, "A\nC") == ZX_OK);
    ZX_ASSERT(zx_console_draw(64, 0, "A") == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_draw(0, 24, "A") == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_draw(0, 0, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_putc('X') == ZX_OK);
    ZX_ASSERT(w3[0x304] == 'X' && w3[0x384] == 0x2e);
    ZX_ASSERT(w3[0x13e] == 'B' && w3[0x13f] == 'C' && w3[0x140] == 0x69);
    ZX_ASSERT(w3[0x1be] == 0x2e && w3[0x1bf] == 0x2e);
    ZX_ASSERT(w3[0x200] == 'A' && w3[0x201] == 0x69);

    w3[62] = 'Q';
    w3[0x1740] = 0x69;              /* padding beyond the last visible cell */
    ZX_ASSERT(zx_console_gotoxy(0, 23) == ZX_OK);
    zx_console_putc('\n');
    ZX_ASSERT(w3[62] == 'Q');        /* default behavior saturates */
    ts_console_set_autoscroll(1);
    zx_console_putc('\n');
    ZX_ASSERT(w3[62] == 'B' && w3[63] == 'C' && w3[0xbe] == 0x2e);
    ZX_ASSERT(w3[0x1700] == ' ' && w3[0x1780] == 0x2e && w3[0x1740] == 0x69);
    zx_console_putc('Z');
    ZX_ASSERT(w3[0x1700] == 'Z');
    ZX_ASSERT(zx_console_gotoxy(63, 23) == ZX_OK);
    zx_console_putc('W');             /* wrapping also scrolls */
    ZX_ASSERT(w3[0x163f] == 'W' && w3[0x173f] == ' ');
    zx_test_step_marker("positioned-and-native-scroll");
}

static void check_zx(void) {
    const ts_surface_t zx = {TS_VIDEO_ZX, 5, w3};

    ts_memory_set_page3(5);
    ZX_ASSERT(ts_video_select_draw_surface(&zx) == ZX_OK);
    ts_console_set_attribute(0x46);
    w3[0] = 0;
    w3[0x20] = 0xa5;
    w3[0x1820] = 0x31;
    w3[0x10e0] = 0xff;
    w3[0x1ae0] = 0xff;
    w3[0x1b00] = 0x69;
    ZX_ASSERT(zx_console_gotoxy(0, 23) == ZX_OK);
    zx_console_putc('\n');
    ZX_ASSERT(w3[0] == 0xa5 && w3[0x1800] == 0x31);
    ZX_ASSERT(w3[0x10e0] == 0 && w3[0x1ae0] == 0x46 && w3[0x1b00] == 0x69);
    zx_test_step_marker("zx-bitmap-and-attribute-scroll");
}

static void check_packed(uint8_t mode, uint8_t base, uint16_t edge, uint16_t width, uint8_t tail,
                         uint8_t blank) {
    const ts_surface_t canvas = {mode, base, 0};

    ts_memory_set_page3(base);
    w3[edge] = 0;
    w3[edge + width] = 0x69;
    ts_memory_set_page3(base + 1);
    w3[0] = 0xa5;                   /* source immediately across a page boundary */
    ts_memory_set_page3(base + tail);
    w3[edge] = 0;
    w3[edge + width] = 0x69;
    ts_memory_set_page3(0x7e);
    w3[0] = 0x69;
    ZX_ASSERT(ts_video_select_draw_surface(&canvas) == ZX_OK);
    zx_set_paper(0xb7);
    ZX_ASSERT(zx_console_gotoxy(0, 23) == ZX_OK);
    zx_console_putc('\n');
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && w3[0] == 0x69);
    ts_memory_set_page3(base);
    ZX_ASSERT(w3[edge] == 0xa5 && w3[edge + width] == 0x69);
    ts_memory_set_page3(base + tail);
    ZX_ASSERT(w3[edge] == blank && w3[edge + width] == 0x69);
}

int main(void) {
    zx_test_init();
    check_text();
    check_zx();
    check_packed(TS_VIDEO_16C, 0x50, 0x3800, 128, 2, 0x77);
    zx_test_step_marker("16c-scroll-cross-page");
    check_packed(TS_VIDEO_256C, 0x40, 0x3000, 256, 5, 0xb7);
    zx_test_step_marker("256c-scroll-cross-page");
    ts_console_set_autoscroll(0);
    zx_test_finish();
    return 0;
}
