#include <baseconf.h>

#include "bc_case.h"

enum { WINDOW_X = 8, WINDOW_Y = 5 };

static const char lines[] = "\x17\x0f\x01"
                            "ERS TEXT WINDOW"
                            "\x0d\x17\x4f"
                            "Alpha"
                            "\x0d\x17\x57"
                            "Bravo"
                            "\x0d\x17\x5f"
                            "Charlie"
                            "\x0d\x17\x67"
                            "Delta";
static bc_ers_window_t window = {
    .x = WINDOW_X,
    .y = WINDOW_Y,
    .height = 6,
    .width = 24,
    .attribute = 0x0f,
    .flags = BC_ERS_WINDOW_NO_FRAME,
    .text = lines,
};

static void check_cell(uint8_t x, uint8_t y, uint8_t character, uint8_t attribute) {
    uint16_t offset = (uint16_t)y * 64u + x / 2u;
    volatile const uint8_t *screen = (const uint8_t *)0xc000u;

    /* Evolution 80x25 screen 0 is mapped in W3. Odd and even columns
     * have separate character planes and interleaved attribute addresses. */
    ZX_ASSERT(screen[(x & 1 ? 0x11c0u : 0x01c0u) + offset] == character);
    ZX_ASSERT(screen[(x & 1 ? 0x21c1u : 0x31c0u) + offset] == attribute);
}

static void check_window(void) {
    const uint8_t x = WINDOW_X + 1;
    const uint8_t y = WINDOW_Y + 1;
    zx_status_t status;

    status = bc_set_video_mode(BC_VIDEO_EVO_TEXT_80);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
    ZX_ASSERT(zx_console_clear() == ZX_OK);
    status = bc_ers_draw_window(&window);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(bc_ers_print_char('!') == ZX_OK);
    check_cell(x, WINDOW_Y, 'E', 0x0f);
    check_cell(x, y, 'A', 0x4f);
    check_cell(x + 5, y + 3, '!', 0x67);
    zx_test_step_shot("draw");

    ZX_ASSERT(bc_ers_scroll_up(&window, 0) == ZX_OK);
    check_cell(x, y, 'B', 0x57);
    check_cell(x, y + 1, 'C', 0x5f);
    check_cell(x, y + 2, 'D', 0x67);
    check_cell(x + 5, y + 2, '!', 0x67);
    zx_test_step_shot("up");

    ZX_ASSERT(bc_ers_scroll_down(&window, 1) == ZX_OK);
    check_cell(x, y, 'B', 0x57);
    check_cell(x, y + 1, 'B', 0x57);
    check_cell(x, y + 2, 'C', 0x5f);
    check_cell(x + 5, y + 3, '!', 0x67);
    zx_test_step_shot("down");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_ers_set_profile(BC_ERS_SERVICES_ROM);
        check_window();
    }
    zx_test_finish();
    return 0;
}
