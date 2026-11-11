#include <arch/z80.h>
#include <stddef.h>
#include <zx/audio.h>
#include <zx_test.h>

extern const uint8_t audio_pt3_module[];

static void audio_test_hold(void) {
    volatile uint16_t delay;
    for (delay = 0; delay != 30000u; ++delay) {
    }
}

static void write_ay(uint8_t reg, uint8_t value) {
    z80_outp(0xfffd, reg);
    z80_outp(0xbffd, value);
}

static void test_ay(void) {
    static const uint16_t periods[] = {418u, 332u, 279u, 209u}; /* C, E, G, C */
    uint8_t note;

    write_ay(7, 0x3e); /* Enable tone A only. */
    write_ay(8, 15);
    write_ay(9, 0);
    write_ay(10, 0);
    for (note = 0; note < sizeof(periods) / sizeof(periods[0]); ++note) {
        write_ay(0, (uint8_t)periods[note]);
        write_ay(1, (uint8_t)(periods[note] >> 8));
        audio_test_hold();
    }
}

static void test_covox(void) {
    /* One continuous 32-sample sine period, high nibble first. */
    static const uint8_t wave[] = {0x89u, 0xabu, 0xdeu, 0xefu, 0xffu, 0xedu, 0xbau, 0x98u,
                                   0x76u, 0x54u, 0x21u, 0x10u, 0x00u, 0x12u, 0x45u, 0x67u};
    static uint8_t samples[256];
    uint16_t index;
    uint8_t repeat;

    ZX_ASSERT(zx_covox_play(NULL, sizeof(samples)) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_covox_play(samples, 0u) == ZX_INVALID_ARGUMENT);
    for (index = 0; index < sizeof(samples); ++index) samples[index] = wave[index & 15u];
    for (repeat = 0; repeat < 30u; ++repeat) {
        ZX_ASSERT(zx_covox_play(samples, sizeof(samples)) == ZX_OK);
    }
}

static void test_pt3(void) {
    uint8_t tick;

    ZX_ASSERT(zx_pt3_init(NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_pt3_init(audio_pt3_module) == ZX_OK);
    zx_pt3_play();
    zx_pt3_start();
    for (tick = 0; tick < 8u; ++tick) {
        zx_pt3_play();
        audio_test_hold();
    }

    zx_pt3_stop();
    zx_pt3_play();
    ZX_ASSERT(zx_pt3_init(audio_pt3_module) == ZX_OK);
    zx_pt3_start();
    zx_pt3_mute();
    zx_pt3_play();
    zx_pt3_stop();

    ZX_ASSERT(zx_pt3_init(audio_pt3_module) == ZX_OK);
    zx_pt3_start();
    zx_pt3_play();
}

int main(void) {
    static const uint8_t covox_silence = 0x88u;

    zx_test_init();

    test_ay();
    zx_test_step_marker("ay");
    write_ay(8, 0);

    test_covox();
    ZX_ASSERT(zx_covox_play(&covox_silence, 1u) == ZX_OK);
    zx_test_step_marker("covox");

    test_pt3();
    zx_test_step_marker("pt3");
    zx_pt3_stop();

    zx_test_finish();
    return 0;
}
