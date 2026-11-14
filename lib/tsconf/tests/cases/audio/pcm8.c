#include <tsconf.h>
#include <string.h>
#include <stdlib.h>
#include <im2.h>
#include <zx_test.h>

static volatile uint8_t ticks;
static uint8_t samples[512];
extern uint8_t ts__cache_mask;
static void tick(void) {
    ++ticks;
}

static void expect_restored(uint8_t page, uint8_t iff) {
    zx_cpu_speed_t speed;
    ZX_ASSERT(ts_memory_get_page3() == page);
    ZX_ASSERT(zx_get_cpu_speed(&speed) == ZX_OK && speed == ZX_CPU_14_MHZ);
    ZX_ASSERT(ts__cache_mask == 5);
    ZX_ASSERT(zx_interrupt_save_disable() == iff);
    zx_interrupt_restore(iff);
}

int main(void) {
    zx_pcm8_banked_t pcm = {0x40, 0x3f00, 512, 255};
    ts_window_lease_t native_lease;
    zx_ram_lease_t lease;
    uint8_t previous;
    zx_test_init();
    ts_set_cpu_speed_and_cache(ZX_CPU_14_MHZ, 0);
    ts_memory_set_cache(5);
    ts_map_ram_page(ZX_WINDOW_3, 0x42);
    ZX_ASSERT(zx_pcm8_play_banked(0, ZX_WINDOW_3, &lease) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_pcm8_play_banked((void *)0xbffb, ZX_WINDOW_3, &lease) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_pcm8_play_banked(&pcm, ZX_WINDOW_1, &lease) == ZX_UNSUPPORTED);
    pcm.delay = 0;
    ZX_ASSERT(zx_pcm8_play_banked(&pcm, ZX_WINDOW_3, &lease) == ZX_INVALID_ARGUMENT);
    pcm.delay = 255;
    pcm.length = 0;
    ZX_ASSERT(zx_pcm8_play_banked(&pcm, ZX_WINDOW_3, &lease) == ZX_INVALID_ARGUMENT);
    pcm.length = 512;
    pcm.first_page = 255;
    ZX_ASSERT(zx_pcm8_play_banked(&pcm, ZX_WINDOW_3, &lease) == ZX_INVALID_ARGUMENT);
    pcm.first_page = 0x40;
    pcm.offset = 16384;
    ZX_ASSERT(zx_pcm8_play_banked(&pcm, ZX_WINDOW_3, &lease) == ZX_INVALID_ARGUMENT);
    pcm.offset = 0x3f00;
    ZX_ASSERT(ts_window_acquire(ZX_WINDOW_3, 0x43, &native_lease) == ZX_OK);
    ZX_ASSERT(zx_pcm8_play_banked(&pcm, ZX_WINDOW_3, &lease) == ZX_BUSY);
    expect_restored(0x43, 0);
    ZX_ASSERT(ts_window_release(&native_lease) == ZX_OK);
    expect_restored(0x42, 0);

    /* Zero is audio data, not a terminator. Each plateau is long enough for
     * host audio capture to distinguish order and both sides of the bank. */
    ts_map_ram_page(ZX_WINDOW_3, 0x40);
    memset((void *)0xff00, 0, 256);
    ts_map_ram_page(ZX_WINDOW_3, 0x41);
    memset((void *)0xc000, 255, 256);
    ts_map_ram_page(ZX_WINDOW_3, 0x42);
    ZX_ASSERT(zx_pcm8_play_banked(&pcm, ZX_WINDOW_3, &lease) == ZX_OK);
    expect_restored(0x42, 0);
    ZX_ASSERT(zx_acquire_ram(ZX_WINDOW_3, 0x43, &lease) == ZX_OK);
    ZX_ASSERT(zx_acquired_ram_set_page(&lease, 0x44) == ZX_OK);
    ZX_ASSERT(ts_memory_get_page3() == 0x44);
    ZX_ASSERT(zx_release_ram(&lease) == ZX_OK);
    zx_test_step_marker("banked");

    ZX_ASSERT(zx_covox_play(0, 1, 18) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_covox_play(samples, 0, 18) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_covox_play(samples, 1, 0) == ZX_INVALID_ARGUMENT);
    memset(samples, 255, 256);
    memset(samples + 256, 0, 256);
    ZX_ASSERT(zx_covox_play(samples, 512, 255) == ZX_OK);
    expect_restored(0x42, 0);
    zx_test_step_marker("contiguous");

    /* Use z88dk's full register-saving generic ISR through its C API. The
     * test reserves W3 for the vector/handler only during this section. */
    memset((void *)0xf000, 0xf1, 257);
    im2_CreateGenericISR(1, (void *)0xf1f1);
    im2_Init_fastcall((void *)0xf000);
    im2_InstallISR(255, (void *)0xf1f1);
    im2_RegHookLast(255, tick);
    ts_irq_set_frame_position(0, 0, 0);
    ts_io_set_interrupt_mask(1);
    zx_interrupt_enable(1);
    ZX_ASSERT(zx_wait_frame(&ticks) == ZX_OK);
    previous = ticks;
    ZX_ASSERT(zx_wait_frame(&ticks) == ZX_OK && ticks != previous);
    /* PCM suppresses interrupts while W3 (including this ISR) is borrowed. */
    pcm.length = 1;
    pcm.delay = 18;
    ZX_ASSERT(zx_pcm8_play_banked(&pcm, ZX_WINDOW_3, &lease) == ZX_OK);
    expect_restored(0x42, 1);
    ZX_ASSERT(zx_wait_frame(&ticks) == ZX_OK);
    zx_interrupt_enable(0);
    ts_io_set_interrupt_mask(0);
    zx_test_step_marker("im2");
    zx_test_finish();
    return 0;
}
