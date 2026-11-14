#include <arch/z80.h>
#include <zx/audio.h>
#include <zx/interrupt.h>
#include <zx_test.h>

static void write_ay(uint8_t reg, uint8_t value) {
    z80_outp(0xfffd, reg);
    z80_outp(0xbffd, value);
}

static uint8_t read_ay(uint8_t reg) {
    z80_outp(0xfffd, reg);
    return z80_inp(0xfffd);
}

int main(void) {
    zx_test_init();
    /* Distinct register values prove that two different chips are selected. */
    ZX_ASSERT(zx_ay_select_chip(ZX_AY_CHIP_0) == ZX_OK);
    write_ay(0, 0x35);
    write_ay(8, 12);
    ZX_ASSERT(zx_ay_select_chip(ZX_AY_CHIP_1) == ZX_OK);
    write_ay(0, 0x67);
    write_ay(8, 9);
    ZX_ASSERT(zx_ay_select_chip(ZX_AY_CHIP_0) == ZX_OK);
    ZX_ASSERT(read_ay(0) == 0x35 && read_ay(8) == 12);
    ZX_ASSERT(zx_ay_select_chip(ZX_AY_CHIP_1) == ZX_OK);
    ZX_ASSERT(read_ay(0) == 0x67 && read_ay(8) == 9);
    zx_test_step_marker("chip-isolation");

    /* Invalid values must change neither selected chip nor selected register. */
    ZX_ASSERT(read_ay(0) == 0x67);
    ZX_ASSERT(zx_ay_select_chip((zx_ay_chip_t)2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(z80_inp(0xfffd) == 0x67);
    ZX_ASSERT(zx_ay_select_chip((zx_ay_chip_t)255) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(z80_inp(0xfffd) == 0x67);
    ZX_ASSERT(zx_interrupt_save_disable() == 0);
    zx_test_step_marker("invalid-selection");

    /* Player output follows the selected chip and leaves the other untouched. */
    zx_ayfx_stop();
    ZX_ASSERT(read_ay(8) == 0);
    ZX_ASSERT(zx_ay_select_chip(ZX_AY_CHIP_0) == ZX_OK);
    ZX_ASSERT(read_ay(8) == 12 && read_ay(0) == 0x35);
    zx_ayfx_stop();
    ZX_ASSERT(read_ay(8) == 0);
    zx_test_step_marker("selected-player-output");
    zx_test_finish();
    return 0;
}
