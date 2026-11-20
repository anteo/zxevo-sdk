#include <tsconf.h>
#include <zx_test.h>

static volatile uint8_t frame_count;
static volatile uint8_t line_count;

/* clang-format off */
static void frame_handler(void) __naked {
    __asm
        push af
        ld a,(_frame_count)
        inc a
        ld (_frame_count),a
        pop af
        ei
        reti
    __endasm;
}

static void line_handler(void) __naked {
    __asm
        push af
        ld a,(_line_count)
        inc a
        ld (_line_count),a
        pop af
        ei
        reti
    __endasm;
}
/* clang-format on */

int main(void) {
    volatile uint8_t *const vectors = (volatile uint8_t *)0x40fdu;
    uint16_t handler;
    uint16_t polls;
    uint32_t period = 0;
    uint8_t previous_frame, previous_line;

    zx_test_init();
    ZX_ASSERT(zx_frame_period(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_frame_period(&period) == ZX_OK && period == 71680ul);
    ZX_ASSERT(ts_irq_set_frame_position(223, 319, 15) == ZX_OK);
    ZX_ASSERT(ts_irq_set_frame_position(224, 0, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_irq_set_frame_position(0, 320, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_irq_set_frame_position(0, 0, 16) == ZX_INVALID_ARGUMENT);
    zx_test_step_marker("frame-compare");

    handler = (uint16_t)(uintptr_t)line_handler;
    vectors[0] = (uint8_t)handler;
    vectors[1] = (uint8_t)(handler >> 8);
    handler = (uint16_t)(uintptr_t)frame_handler;
    vectors[2] = (uint8_t)handler;
    vectors[3] = (uint8_t)(handler >> 8);
    /* clang-format off */
    __asm
        ld a,0x40
        ld i,a
        im 2
    __endasm;
    /* clang-format on */
    /* After each line IRQ, zx_wait_frame briefly disables INT to compare
     * the counter. IRQ entry, the handler and rearming HALT take about
     * 120 T-states. Put the frame compare after that window. */
    ZX_ASSERT(ts_irq_set_frame_position(192, 300, 0) == ZX_OK);
    ts_io_set_interrupt_mask(TS_IRQ_FRAME | TS_IRQ_LINE);
    zx_test_step_marker("irq-configured");

    /* Poll for several frames before testing the blocking wait. If either
     * source is missing, report which one without entering HALT. */
    zx_interrupt_enable(1);
    for (polls = 16384; polls && (!frame_count || !line_count); --polls) {
    }
    zx_interrupt_enable(0);
    previous_frame = frame_count;
    previous_line = line_count;
    if (!previous_frame && !previous_line)
        zx_test_fail(__LINE__, "neither FRAME nor LINE interrupt arrived");
    else if (!previous_frame)
        zx_test_fail(__LINE__, "LINE arrived, FRAME did not");
    else if (!previous_line)
        zx_test_fail(__LINE__, "FRAME arrived, LINE did not");
    zx_test_step_marker("irq-delivery");
    if (!previous_frame || !previous_line) {
        ts_io_set_interrupt_mask(0);
        zx_test_finish();
        return 0;
    }

    zx_interrupt_enable(1);
    ZX_ASSERT(zx_wait_frame(&frame_count) == ZX_OK && frame_count != 0);
    previous_frame = frame_count;
    previous_line = line_count;
    ZX_ASSERT(zx_wait_frame(&frame_count) == ZX_OK);
    zx_interrupt_enable(0);
    ts_io_set_interrupt_mask(0);
    ZX_ASSERT(frame_count == (uint8_t)(previous_frame + 1u));
    ZX_ASSERT(line_count != previous_line);
    zx_test_step_marker("frame-and-line");
    zx_test_finish();
    return 0;
}
