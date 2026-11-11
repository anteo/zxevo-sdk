#include <baseconf.h>
#include <zx/console.h>
#include <zx/printf.h>
#include <baseconf/font.h>
#include <baseconf/text.h>

#include "bc_case.h"

extern uint8_t _console_x, _console_y;

static void test_graphics_console(void) {
    ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
    ZX_ASSERT(zx_console_get_font() == NULL);
    ZX_ASSERT(zx_console_putc('A') == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_console_puts("A") == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_console_set_font(NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_OK);
    ZX_ASSERT(zx_console_get_font() == &zx_font5);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(41, 23) == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(42, 23) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_gotoxy(0, 24) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(_console_x == 41 && _console_y == 23);
    ZX_ASSERT(zx_console_putc('A') == ZX_OK);
    ZX_ASSERT(zx_console_putc('\n') == ZX_OK);
    ZX_ASSERT(zx_console_putc('\r') == ZX_OK);
    ZX_ASSERT(zx_console_putc('\b') == ZX_OK);
    ZX_ASSERT(zx_console_putc('\t') == ZX_OK);

    ZX_ASSERT(zx_console_gotoxy(40, 20) == ZX_OK);
    ZX_ASSERT(zx_console_puts("AB\nC") == ZX_OK);
    ZX_ASSERT(_console_x == 1 && _console_y == 22);
    ZX_ASSERT(zx_console_puts(NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_draw(0, 0, "draw") == ZX_OK);
    ZX_ASSERT(zx_console_draw(0, 0, NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_draw(41, 0, "clip") == ZX_OK);
    ZX_ASSERT(zx_console_draw(42, 0, "edge") == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_text_draw_font(0, 1, "raw", &zx_font5_data[0][0]) == ZX_OK);
    ZX_ASSERT(bc_text_draw_font(31, 1, "clip", &zx_font5_data[0][0]) == ZX_OK);
    ZX_ASSERT(bc_text_draw_font(0, 1, NULL, &zx_font5_data[0][0]) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_text_draw_font(0, 1, "raw", NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_text_draw_font(32, 0, "edge", &zx_font5_data[0][0]) == ZX_INVALID_ARGUMENT);

    zx_test_step_marker("graphics_api");
}

static void test_hardware_text(void) {
    ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ATM_TEXT_80) == ZX_OK);

    ZX_ASSERT(zx_console_set_font(&zx_font5) == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_get_font() == &zx_font5);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(79, 24) == ZX_OK);
    ZX_ASSERT(zx_console_draw(79, 23, "AB") == ZX_OK);
    ZX_ASSERT(zx_console_draw_op(79, 23, "AB", ZX_TEXT_TRANSPARENT) == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_TRANSPARENT) == ZX_OK);
    ZX_ASSERT(zx_console_putc('A') == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_puts("ABC") == ZX_UNSUPPORTED);
    ZX_ASSERT(zx_console_printf("ABCD") == -1);
    ZX_ASSERT(zx_console_set_text_bg(ZX_TEXT_OPAQUE) == ZX_OK);
    ZX_ASSERT(_console_x == 79 && _console_y == 24);
    ZX_ASSERT(zx_console_gotoxy(80, 24) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_gotoxy(0, 25) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_console_putc('Z') == ZX_OK);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(79, 24) == ZX_OK);
    ZX_ASSERT(zx_console_putc('A') == ZX_OK);
    ZX_ASSERT(zx_console_putc('\n') == ZX_OK);
    ZX_ASSERT(zx_console_puts("A\tB\rC\bD\ntext mode") == ZX_OK);
    ZX_ASSERT(zx_console_puts(NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_text_draw_font(0, 0, "unsupported", &zx_font5_data[0][0]) == ZX_UNSUPPORTED);

    zx_test_step_marker("text_api");
}

static void test_cursor_after_mode_change(void) {
    ZX_ASSERT(zx_console_gotoxy(79, 24) == ZX_OK);
    ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
    ZX_ASSERT(_console_x == 0 && _console_y == 0);

    ZX_ASSERT(zx_console_gotoxy(41, 23) == ZX_OK);
    ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ATM_TEXT_80) == ZX_OK);
    ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
    ZX_ASSERT(_console_x == 41 && _console_y == 23);
}

int main(void) {
    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
    test_graphics_console();
    test_hardware_text();
    test_cursor_after_mode_change();
    zx_test_finish();
    return 0;
}
