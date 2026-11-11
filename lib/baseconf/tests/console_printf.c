#include <baseconf.h>
#include <intrinsic.h>

#ifndef CONSOLE_TEST_MODE
#define CONSOLE_TEST_MODE BC_VIDEO_ATM_640
#endif
#ifndef CONSOLE_TEST_FONT
#define CONSOLE_TEST_FONT 5
#endif
#ifndef CONSOLE_TEST_SCROLL
#define CONSOLE_TEST_SCROLL 0
#endif

#if CONSOLE_TEST_SCROLL
static void exercise_scroll(uint8_t penultimate_row, volatile uint8_t *edge) {
    uint8_t cleared;
    (void)zx_console_gotoxy(0, penultimate_row);
    (void)zx_console_printf("scroll keeper\n");
    if (edge) *edge = 1;
    (void)zx_console_putc('\n');
    cleared = edge ? (uint8_t)(*edge == 0) : 1u;
    (void)zx_console_printf("scroll edge clear=%u", (unsigned int)cleared);
}
#endif

int main(void) {
#if CONSOLE_TEST_MODE == 4 || CONSOLE_TEST_MODE == 5 || CONSOLE_TEST_MODE == 6
    const uint8_t pinned = 0x06;
#else
    const uint8_t pinned = 0x07;
#endif
    uint16_t max_unsigned = 65535u;
#if CONSOLE_TEST_MODE == 0
    static char long_text[301];
#if CONSOLE_TEST_FONT != 8
    uint16_t i;
    int printed;
#endif
#endif
    static const char wrap[] = "0123456789012345678901234567890123456789012345678901234567890123456"
                               "78901234567890123456789012345678901234567890123456789";
    intrinsic_di();
    bc_ers_set_profile(BC_ERS_NONE);
    bc_set_pinned_windows(pinned);
    if (bc_set_video_mode(CONSOLE_TEST_MODE) != ZX_OK) return 2;
#if CONSOLE_TEST_MODE != 4
    if (zx_show_screen(ZX_SCREEN_0) != ZX_OK) return 3;
#endif
    zx_set_border_color(6);
#if CONSOLE_TEST_MODE == 4
    {
        const bc_surface_t surface = {BC_VIDEO_ATM_640, 1, 5};
        if (bc_map_ram_page(ZX_WINDOW_3, 1) != ZX_OK) return 6;
        if (bc_select_draw_surface(&surface) != ZX_OK) return 7;
    }
#elif CONSOLE_TEST_MODE == 5 || CONSOLE_TEST_MODE == 6
    {
#if CONSOLE_TEST_MODE == 5
        const bc_surface_t surface = {BC_VIDEO_ATM_TEXT_80, 1, 5};
        if (bc_map_ram_page(ZX_WINDOW_3, 1) != ZX_OK) return 6;
#else
        const bc_surface_t surface = {BC_VIDEO_EVO_TEXT_80, 8, 8};
        if (bc_map_ram_page(ZX_WINDOW_3, 8) != ZX_OK) return 6;
#endif
        if (bc_select_draw_surface(&surface) != ZX_OK) return 7;
    }
#elif CONSOLE_TEST_MODE == 0
    if (zx_select_draw_screen(ZX_SCREEN_0) != ZX_OK) return 6;
#endif
    zx_set_ink(7);
    zx_set_paper(0);
#if CONSOLE_TEST_MODE == 4
#if CONSOLE_TEST_FONT == 8
    if (zx_console_set_font(&zx_font8) != ZX_OK) return 4;
#else
    if (zx_console_set_font(&zx_font5) != ZX_OK) return 5;
#endif
    {
        volatile uint8_t *pixels = (volatile uint8_t *)0x4000;
        uint16_t offset;
        for (offset = 0; offset < 8000u; ++offset) {
            pixels[offset] = 0;
            pixels[0x2000u + offset] = 0;
        }
    }
    (void)zx_console_gotoxy(0, 0);
#if CONSOLE_TEST_FONT == 8
    (void)zx_console_printf("ATM640 font8 80x25\nx=%d u=%u h=%02X s=%s c=%c %%\n", (int16_t)-32768,
                            max_unsigned, 0x2au, "font8", 'A');
#else
    (void)zx_console_printf("ATM640 font5 106x25\nx=%d u=%u h=%02X s=%s c=%c %%\n", (int16_t)-32768,
                            max_unsigned, 0x2au, "font5", 'A');
    (void)zx_console_gotoxy(0, 3);
    (void)zx_console_printf("wrap:%s", wrap);
#endif
#if CONSOLE_TEST_SCROLL
    exercise_scroll(23, (volatile uint8_t *)0x7F3F);
#endif
    return 0;
#elif CONSOLE_TEST_MODE == 5 || CONSOLE_TEST_MODE == 6
    if (zx_console_clear() != ZX_OK) return 8;
    if (zx_console_gotoxy(0, 0) != ZX_OK) return 9;
    if (zx_console_printf("TEXT 80x25 x=%d u=%u h=%02X s=%s c=%c %%\n", (int16_t)-32768,
                          max_unsigned, 0x2au, "text", 'A') < 0)
        return 10;
#if CONSOLE_TEST_MODE == 6
    if (*(volatile uint8_t *)0xC1C0 != 'T' || *(volatile uint8_t *)0xD1C0 != 'E') return 11;
    if (*(volatile uint8_t *)0xF1C0 != 7u) return 12;
#endif
    (void)zx_console_printf("wrap:%s", wrap);
#if CONSOLE_TEST_SCROLL
    exercise_scroll(23, 0);
#endif
    return 0;
#else
    if (zx_console_set_font(&zx_font8) != ZX_OK && CONSOLE_TEST_MODE != BC_VIDEO_ATM_TEXT_80 &&
        CONSOLE_TEST_MODE != BC_VIDEO_EVO_TEXT_80)
        return 4;
    (void)zx_console_clear();
    (void)zx_console_gotoxy(0, 0);
    (void)zx_console_printf("x=%d u=%u h=%02X s=%s c=%c %%\n", (int16_t)-32768, max_unsigned, 0x2au,
                            "font8", 'A');
#if CONSOLE_TEST_FONT != 8
    (void)zx_console_printf("zero=%d pos=%d width=%05d left=%-5u\n", 0, 12, -42, 7u);

    if (CONSOLE_TEST_MODE != BC_VIDEO_ATM_TEXT_80 && CONSOLE_TEST_MODE != BC_VIDEO_EVO_TEXT_80) {
        if (zx_console_set_font(&zx_font5) != ZX_OK) return 5;
        (void)zx_console_clear();
        (void)zx_console_printf("font5 pitch6: %s pq\n", "compact 5x7");
        (void)zx_console_printf("x=%d u=%u h=%02X s=%s c=%c %%\n", (int16_t)-32768, max_unsigned,
                                0x2au, "font5", 'A');
        (void)zx_console_printf("zero=%d width=%05d left=%-5u\n", 0, -42, 7u);
        (void)zx_console_printf("single hex=%X str=%s c=%c\n", 42u, "OK", 'Z');
        (void)zx_console_printf("wrap:%s", wrap);
#if CONSOLE_TEST_MODE == 0
        for (i = 0; i < 300u; ++i) long_text[i] = 'a' + (char)(i % 26u);
        long_text[300] = 0;
        (void)zx_console_gotoxy(0, 10);
        printed = zx_console_printf("%s", long_text);
        (void)zx_console_printf("\nlength=%d", printed);
#endif
#if CONSOLE_TEST_SCROLL
        exercise_scroll(22, (volatile uint8_t *)0x57FF);
#endif
    }
#endif
    return 0;
#endif
}
