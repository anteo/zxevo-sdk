#include <baseconf.h>

#include "bc_case.h"

static uint8_t wait_scancode(void) {
    uint16_t polls = 4000;
    do {
        uint8_t code;
        if (zx_ps2_scancode_read(&code) != ZX_OK) return 0;
        /* The emulator uses FF for an empty FIFO, unlike the AVR. */
        if (code != 0 && code != 0xff) return code;
    } while (--polls);
    return 0;
}

int main(void) {
    uint16_t modifiers = 0xffffu;
    uint8_t code;
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(zx_ps2_scancode_read(&code) == ZX_UNSAFE_CONTEXT);
        ZX_ASSERT(zx_avr_window_select(ZX_AVR_WINDOW_PS2_LOG) == ZX_OK);
        ZX_ASSERT(zx_ps2_scancode_read(0) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(zx_ps2_modifiers(0) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(zx_ps2_modifiers(&modifiers) == ZX_OK && modifiers == 0);
        ZX_ASSERT(zx_ps2_log_clear() == ZX_OK);
        zx_test_step_marker("inject_a");

        ZX_ASSERT(wait_scancode() == 0x1c);
        ZX_ASSERT(wait_scancode() == 0xf0);
        ZX_ASSERT(wait_scancode() == 0x1c);
        zx_test_step_marker("make_break");
    }
    zx_test_finish();
    return 0;
}
