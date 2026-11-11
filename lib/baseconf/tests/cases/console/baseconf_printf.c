#include <baseconf.h>
#include <zx/console.h>
#include <baseconf/font.h>
#include <zx/printf.h>
#include <intrinsic.h>

#include "bc_case.h"

static const char wrap_text[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz"
                                "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz";

static void report_counts(const char *tag, int format_count, int wrap_count) {
    zx_test_output_begin();
    zx_test_output(tag);
    zx_test_output(" format=");
    zx_test_output_u16((uint16_t)format_count);
    zx_test_output(" wrap=");
    zx_test_output_u16((uint16_t)wrap_count);
    zx_test_output_char('\n');
    zx_test_step_text("counts");
}

static void draw_graphics_case(bc_video_mode_t mode, const zx_font_t *font, const char *tag) {
    int format_count, wrap_count;
    zx_console_size_t grid = {0, 0};
    if (bc_set_video_mode(mode) != ZX_OK) {
        zx_test_step_skip(tag, "video mode unavailable");
        zx_test_step_skip("counts", "video mode unavailable");
        return;
    }
    ZX_ASSERT(zx_console_set_font(font) == ZX_OK);
    zx_set_ink(10);
    zx_set_paper(1);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    format_count = zx_console_printf("%d|%u|%04X|%-4s|%c|%%\n", -42, 65535u, 42u, "ok", 'Z');
    ZX_ASSERT(format_count == 24);
    (void)zx_console_printf("zero:%05d left:%-5u\n", -7, 9u);
    ZX_ASSERT(zx_console_gotoxy(2, 3) == ZX_OK);
    (void)zx_console_printf("cursor at 2,3");
    ZX_ASSERT(zx_console_gotoxy(0, 7) == ZX_OK);
    ZX_ASSERT(zx_console_putc('!') == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(0, 8) == ZX_OK);
    wrap_count = zx_console_printf("wrap:%s", wrap_text);
    ZX_ASSERT(wrap_count == (int)(5u + sizeof(wrap_text) - 1u));
    ZX_ASSERT(zx_console_get_size(&grid) == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(0, (uint8_t)(grid.rows - 1u)) == ZX_OK);
    (void)zx_console_printf("bottom row\nscroll one\nscroll two\n");
    ZX_ASSERT(zx_console_gotoxy(0, 0) == ZX_OK);
    (void)zx_console_printf("%d|%u|%04X|%-4s|%c|%%\n", -42, 65535u, 42u, "ok", 'Z');
    zx_test_step_shot(tag);
    report_counts(tag, format_count, wrap_count);
}

static void draw_text_case(bc_video_mode_t mode, const char *tag) {
    int format_count, wrap_count;
    if (bc_set_video_mode(mode) != ZX_OK) {
        zx_test_step_skip(tag, "video mode unavailable");
        zx_test_step_skip("counts", "video mode unavailable");
        return;
    }
    zx_set_ink(14);
    zx_set_paper(1);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    format_count = zx_console_printf("%d|%u|%04X|%-4s|%c|%%\n", -42, 65535u, 42u, "ok", 'Z');
    ZX_ASSERT(format_count == 24);
    (void)zx_console_printf("zero:%05d left:%-5u\n", -7, 9u);
    ZX_ASSERT(zx_console_gotoxy(0, 7) == ZX_OK);
    ZX_ASSERT(zx_console_putc('!') == ZX_OK);
    ZX_ASSERT(zx_console_gotoxy(0, 8) == ZX_OK);
    wrap_count = zx_console_printf("wrap:%s", wrap_text);
    ZX_ASSERT(wrap_count == (int)(5u + sizeof(wrap_text) - 1u));
    ZX_ASSERT(zx_console_gotoxy(0, 24) == ZX_OK);
    (void)zx_console_printf("bottom row\nscroll one\nscroll two\n");
    ZX_ASSERT(zx_console_gotoxy(0, 0) == ZX_OK);
    (void)zx_console_printf("%d|%u|%04X|%-4s|%c|%%\n", -42, 65535u, 42u, "ok", 'Z');
    zx_test_step_shot(tag);
    report_counts(tag, format_count, wrap_count);
}

int main(void) {
    intrinsic_di();
    if (bc_case_init() != ZX_OK) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
    draw_graphics_case(BC_VIDEO_ZX_256, &zx_font8, "zx256_font8");
    draw_graphics_case(BC_VIDEO_ZX_MULTICOLOR, &zx_font8, "multicolor_font8");
    draw_graphics_case(BC_VIDEO_PENTAGON_256, &zx_font8, "pentagon_font8");
    draw_graphics_case(BC_VIDEO_ATM_320, &zx_font8, "atm320_font8");
    draw_graphics_case(BC_VIDEO_ATM_640, &zx_font8, "atm640_font8");
    draw_text_case(BC_VIDEO_ATM_TEXT_80, "atm_text80");
    draw_text_case(BC_VIDEO_EVO_TEXT_80, "evo_text80");
    zx_test_finish();
    return 0;
}
