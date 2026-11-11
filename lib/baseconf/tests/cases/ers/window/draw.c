#include <baseconf.h>
#include <stddef.h>
#include <string.h>

#include "bc_case.h"

static const char title[] = "\x17\x4f\x03"
                            "ERS WINDOW";
static const char message[] = "\x16\x09\x38\x17\x4f\x03"
                              "Print message"
                              "\x0d\x09\x03"
                              "Single char: ";
static bc_ers_window_t window = {
    .x = 5,
    .y = 6,
    .height = 8,
    .width = 22,
    .attribute = 0x4f,
    .text = title,
};
static bc_ers_window_t empty_window = {
    .x = 5,
    .y = 6,
    .height = 8,
    .width = 22,
    .attribute = 0x4f,
    .flags = BC_ERS_WINDOW_NO_TEXT | BC_ERS_WINDOW_NO_FRAME,
};

typedef char window_layout_matches_ers[sizeof(bc_ers_window_t) == 20 &&
                                               offsetof(bc_ers_window_t, flags) == 6 &&
                                               offsetof(bc_ers_window_t, current_item) == 8 &&
                                               offsetof(bc_ers_window_t, text) == 12 &&
                                               offsetof(bc_ers_window_t, hotkeys) == 18
                                           ? 1
                                           : -1];

static void check_draw(void) {
    volatile const uint8_t *const top_border = (const uint8_t *)0x40c5u;
    volatile const uint8_t *const middle_attr = (const uint8_t *)0x5926u;
    zx_status_t status;
    uint8_t scanline;
    uint8_t glyph = 0;

    status = bc_set_video_mode(BC_VIDEO_ZX_256);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    status = bc_select_screen(ZX_SCREEN_0);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    memset((void *)0x4000u, 0, 6912u);

    status = bc_ers_draw_window(&empty_window);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(bc_ers_print_char('!') == ZX_OK);
    for (scanline = 0; scanline < 8u; ++scanline) {
        glyph |= top_border[(uint16_t)scanline << 8];
    }
    ZX_ASSERT(glyph != 0);
    zx_test_step_marker("char_after_empty_window");

    status = bc_ers_draw_window(&window);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(*top_border == 0xff);
    ZX_ASSERT(*middle_attr == 0x4f);
    zx_test_step_shot("frame");

    ZX_ASSERT(bc_ers_print_message(&window, message) == ZX_OK);
    ZX_ASSERT(bc_ers_print_char('!') == ZX_OK);
    zx_test_step_shot("print");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_ers_set_profile(BC_ERS_SERVICES_ROM);
        check_draw();
    }
    zx_test_finish();
    return 0;
}
