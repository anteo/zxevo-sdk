#include <stddef.h>
#include <string.h>
#include <tsconf.h>
#include <zx_test.h>

static volatile uint8_t *const backing = (volatile uint8_t *)0xc000;
static const uint16_t colors[] = {0x1234, 0x4567};
static const ts_sprite_t sprite = {0x2345, 0x6789, 0xabcd};

static void test_ranges(void) {
    memset((void *)backing, 0x5a, 1024);
    ZX_ASSERT(ts_video_upload_palette((zx_window_t)4, 0, colors, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_video_upload_palette(ZX_WINDOW_3, 0, colors, 257) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_video_upload_palette(ZX_WINDOW_3, 255, colors, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_video_upload_palette(ZX_WINDOW_3, 255, NULL, 0) == ZX_OK);
    ZX_ASSERT(ts_video_upload_sprites((zx_window_t)4, 0, &sprite, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_video_upload_sprites(ZX_WINDOW_3, 84, &sprite, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_video_upload_sprites(ZX_WINDOW_3, 0, &sprite, 86) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_video_upload_sprites(ZX_WINDOW_3, 86, NULL, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_video_upload_sprites(ZX_WINDOW_3, 85, NULL, 0) == ZX_OK);
    ZX_ASSERT(backing[0] == 0x5a && backing[510] == 0x5a && backing[1016] == 0x5a);
    ZX_ASSERT(ts_memory_get_page3() == 0x70);
}

static void test_palette(void) {
    ZX_ASSERT(ts_video_upload_palette(ZX_WINDOW_3, 255, colors, 1) == ZX_OK);
    ZX_ASSERT(backing[509] == 0x5a && backing[510] == 0x34 && backing[511] == 0x12);
    ZX_ASSERT(backing[512] == 0x5a);
    ZX_ASSERT(zx_interrupt_save_disable() == 0);
    ZX_ASSERT(ts_video_upload_palette(ZX_WINDOW_3, 0, colors, 2) == ZX_OK);
    ZX_ASSERT(backing[0] == 0x34 && backing[1] == 0x12);
    ZX_ASSERT(backing[2] == 0x67 && backing[3] == 0x45 && backing[4] == 0x5a);
    ZX_ASSERT(ts_video_upload_palette(ZX_WINDOW_3, 0, NULL, 256) == ZX_OK);
    ZX_ASSERT(backing[0] == 0 && backing[511] == 0 && backing[512] == 0x5a);
}

static void test_sprites(void) {
    ZX_ASSERT(ts_video_upload_sprites(ZX_WINDOW_3, 84, &sprite, 1) == ZX_OK);
    ZX_ASSERT(backing[1015] == 0x5a && backing[1016] == 0x45 && backing[1017] == 0x23);
    ZX_ASSERT(backing[1018] == 0x89 && backing[1019] == 0x67);
    ZX_ASSERT(backing[1020] == 0xcd && backing[1021] == 0xab && backing[1022] == 0x5a);
    ZX_ASSERT(ts_video_upload_sprites(ZX_WINDOW_3, 0, NULL, TS_SPRITE_COUNT) == ZX_OK);
    ZX_ASSERT(backing[512] == 0 && backing[1016] == 0 && backing[1021] == 0);
    ZX_ASSERT(backing[1022] == 0x5a);
    /* No interrupt source is active; test preservation of enabled IFF. */
    ts_io_set_interrupt_mask(0);
    zx_interrupt_enable(1);
    ZX_ASSERT(ts_video_upload_sprites(ZX_WINDOW_3, 1, &sprite, 1) == ZX_OK);
    ZX_ASSERT(zx_interrupt_save_disable() == 1);
    ZX_ASSERT(backing[517] == 0 && backing[518] == 0x45 && backing[523] == 0xab);
    ZX_ASSERT(backing[524] == 0 && ts_memory_get_page3() == 0x70);
}

int main(void) {
    zx_test_init();
    ts_memory_set_cache(0);
    ts_map_ram_page(ZX_WINDOW_3, 0x70);
    ts_fmaps_disable();
    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_HIDE_TSU);
    test_ranges();
    zx_test_step_marker("ranges");
    test_palette();
    zx_test_step_marker("palette");
    test_sprites();
    zx_test_step_marker("sprites-and-iff");
    zx_test_finish();
    return 0;
}
