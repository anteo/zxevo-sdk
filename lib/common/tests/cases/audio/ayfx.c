#include <arch/z80.h>
#include <stddef.h>
#include <zx/audio.h>
#include <zx/interrupt.h>
#include <zx_test.h>

/* AFB offsets are relative to each offset's high byte. */
static const uint8_t noise_bank[] = {1, 1, 0, 0x6c, 0x34, 0x02, 0x07, 0x81, 0xd0, 0x20};
static const uint8_t voices_bank[] = {
    4,    7,    0,    13,   0,    19,   0,    25,   0,    0xac, 0x34, 0x02, 0x8c, 0x8c,
    0x8c, 0xd0, 0x20, 0xa9, 0x57, 0x01, 0x89, 0x89, 0x89, 0xd0, 0x20, 0xa6, 0x68, 0x02,
    0x86, 0x86, 0x86, 0xd0, 0x20, 0xa3, 0x79, 0x03, 0x83, 0x83, 0x83, 0xd0, 0x20};

static void write_ay(uint8_t reg, uint8_t value) {
    z80_outp(0xfffd, reg);
    z80_outp(0xbffd, value);
}

static uint8_t read_ay(uint8_t reg) {
    z80_outp(0xfffd, reg);
    return z80_inp(0xfffd);
}

static void test_arguments(void) {
    static const uint8_t empty[] = {0};
    ZX_ASSERT(zx_ayfx_play(0, 0) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_ayfx_init(NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_ayfx_init(empty) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_ayfx_init(noise_bank) == ZX_OK);
    ZX_ASSERT(zx_ayfx_play(1, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_ayfx_play(0, -16) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_ayfx_play(0, 16) == ZX_INVALID_ARGUMENT);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(8) == 0);
}

static void test_frames(void) {
    ZX_ASSERT(zx_ayfx_init(noise_bank) == ZX_OK);
    write_ay(7, 0xff);
    write_ay(2, 0x56);
    write_ay(9, 9);
    ZX_ASSERT(zx_ayfx_play(0, 0) == ZX_OK);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(0) == 0x34 && read_ay(1) == 2);
    ZX_ASSERT(read_ay(6) == 7 && read_ay(8) == 12);
    ZX_ASSERT(read_ay(7) == 0xf6);
    ZX_ASSERT(read_ay(2) == 0x56 && read_ay(9) == 9);

    /* A music tick can overwrite tone; the next effect frame restores it.
     * Noise is chip-global and changes only on an explicit noise update. */
    write_ay(0, 0x99);
    write_ay(1, 1);
    write_ay(6, 13);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(0) == 0x34 && read_ay(1) == 2);
    ZX_ASSERT(read_ay(6) == 13 && read_ay(8) == 1);
    ZX_ASSERT(read_ay(7) == 0xfe);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(8) == 0 && read_ay(7) == 0xff);
    write_ay(0, 0x88);
    write_ay(8, 5);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(0) == 0x88 && read_ay(8) == 5);
}

static void test_volume_stop(void) {
    ZX_ASSERT(zx_ayfx_init(noise_bank) == ZX_OK);
    ZX_ASSERT(zx_ayfx_play(0, 15) == ZX_OK);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(8) == 15);
    zx_ayfx_stop();
    ZX_ASSERT(zx_ayfx_play(0, -15) == ZX_OK);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(8) == 0);
    write_ay(7, 0x80);
    write_ay(9, 10);
    write_ay(10, 11);
    zx_ayfx_stop();
    ZX_ASSERT(read_ay(8) == 0 && read_ay(9) == 0 && read_ay(10) == 0);
    ZX_ASSERT(read_ay(7) == 0xbf);
    write_ay(8, 7);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(8) == 7);
}

static void test_channels(void) {
    uint8_t frame;
    ZX_ASSERT(zx_ayfx_init(voices_bank) == ZX_OK);
    ZX_ASSERT(zx_ayfx_play(0, 0) == ZX_OK);
    zx_ayfx_frame();
    ZX_ASSERT(zx_ayfx_play(1, 0) == ZX_OK);
    zx_ayfx_frame();
    ZX_ASSERT(zx_ayfx_play(2, 0) == ZX_OK);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(8) == 12 && read_ay(9) == 9 && read_ay(10) == 6);
    /* All channels occupied: replace the oldest effect, on channel A. */
    ZX_ASSERT(zx_ayfx_play(3, 0) == ZX_OK);
    zx_ayfx_frame();
    ZX_ASSERT(read_ay(0) == 0x79 && read_ay(1) == 3);
    ZX_ASSERT(read_ay(2) == 0x57 && read_ay(3) == 1);
    ZX_ASSERT(read_ay(4) == 0x68 && read_ay(5) == 2);
    ZX_ASSERT(read_ay(8) == 3 && read_ay(9) == 9 && read_ay(10) == 6);
    for (frame = 0; frame < 4; ++frame) zx_ayfx_frame();
    ZX_ASSERT(read_ay(8) == 0 && read_ay(9) == 0 && read_ay(10) == 0);
}

int main(void) {
    uint8_t iff;
    zx_test_init();
    iff = zx_interrupt_save_disable();
    test_arguments();
    zx_test_step_marker("arguments");
    test_frames();
    zx_test_step_marker("frames");
    test_volume_stop();
    zx_test_step_marker("volume-stop");
    test_channels();
    zx_test_step_marker("channels");
    zx_ayfx_stop();
    zx_interrupt_restore(iff);
    zx_test_finish();
    return 0;
}
