#include <zx/interrupt.h>
#include <zx_test.h>

#if defined(__TSCONF)
#include <arch/z80.h>
#include <tsconf/io.h>
#include <tsconf/memory.h>
#endif

static volatile uint8_t frame_count;

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
/* clang-format on */

int main(void) {
    volatile uint8_t *const vector = (volatile uint8_t *)0x0038u;
    uint16_t handler = (uint16_t)(uintptr_t)frame_handler;
    uint8_t previous_frame;

    zx_test_init();
#if defined(__TSCONF)
    /* The runner leaves ROM in W0 and masks all TSConf IRQ sources. */
    ts_memory_set_page0(0x20);
    ts_memory_set_config(TS_MEM_W0_DIRECT | TS_MEM_W0_RAM | TS_MEM_W0_WRITE);
    z80_outp(0x22af, 0);
    z80_outp(0x23af, 0);
    z80_outp(0x24af, 0);
    ts_io_set_interrupt_mask(1);
#endif
    vector[0] = 0xc3;
    vector[1] = (uint8_t)handler;
    vector[2] = (uint8_t)(handler >> 8);
    __asm im 1 __endasm;

    ZX_ASSERT(zx_interrupt_save_disable() == 0);
    zx_interrupt_restore(0);
    ZX_ASSERT(zx_wait_frame(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_wait_frame(&frame_count) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(zx_wait_interrupt() == ZX_UNSAFE_CONTEXT);
    zx_interrupt_enable(1);
    ZX_ASSERT(zx_interrupt_save_disable() == 1);
    ZX_ASSERT(zx_interrupt_save_disable() == 0);
    zx_interrupt_restore(1);
    ZX_ASSERT(zx_wait_interrupt() == ZX_OK);
    previous_frame = frame_count;
    ZX_ASSERT(zx_wait_frame(&frame_count) == ZX_OK);
    zx_interrupt_enable(0);
    ZX_ASSERT(frame_count != previous_frame);
    ZX_ASSERT(zx_interrupt_save_disable() == 0);
    zx_test_step_marker("int");
    zx_test_finish();
    return 0;
}
