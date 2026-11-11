#include <string.h>
#include <tsconf.h>
#include <zx_test.h>

/* W3 backs FMAPS during the upload, away from the code and ZXHost. */
#define APERTURE 0xc000u

static uint8_t *const w3 = (uint8_t *)0xc000;
static const uint16_t palette[256] = {TS_PALETTE_RGB555(0, 0, 0), TS_PALETTE_RGB555(0, 0, 31),
                                      TS_PALETTE_RGB555(31, 0, 0), TS_PALETTE_RGB555(0, 31, 0),
                                      [255] = TS_PALETTE_RGB555(0, 31, 0)};
static const ts_sprite_t sprite = {TS_SPRITE_ACTIVE | TS_SPRITE_LEAP | 64u, 64u, 0};

static void check_palette(void) {
    volatile uint8_t *backing = w3;
    uint8_t page;

    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_HIDE_TSU);
    ts_memory_set_page3(0x70);
    backing[0] = 0x5a;
    backing[512] = 0x69;
    ts_fmaps_enable(APERTURE);
    ts_fmaps_write_words(TS_FMAPS_CRAM(APERTURE), palette, 0);
    ZX_ASSERT(backing[0] == 0x5a);
    ts_fmaps_write_words(TS_FMAPS_CRAM(APERTURE), palette, 256);
    ts_fmaps_disable();
    ZX_ASSERT(backing[2] == 0x1f && backing[3] == 0);
    ZX_ASSERT(backing[4] == 0 && backing[5] == 0x7c);
    ZX_ASSERT(backing[510] == 0xe0 && backing[511] == 0x03);
    ZX_ASSERT(backing[512] == 0x69);
    /* After FMAPS is disabled, changing its backing RAM must leave CRAM blue. */
    backing[2] = 0;
    backing[3] = 0;

    /* Each 256c page holds 32 rows of the 512-pixel canvas. Make a red
     * stripe in the second half of row 0. The Y offset wraps to that row. */
    for (page = 0x40; page < 0x50; ++page) {
        ts_memory_set_page3(page);
        memset(w3, 1, 0x4000);
    }
    ts_memory_set_page3(0x40);
    memset(w3 + 272, 2, 32);
    ts_video_set_page(0x40);
    ts_video_set_palette_select(0);
    zx_set_border_color(15);
    ts_video_set_scroll(0x0300, 0x03fe);
    ts_video_set_config(TS_VIDEO_256C | TS_VIDEO_256X192 | TS_VIDEO_HIDE_TSU);
    zx_test_step_shot("palette-and-wrapped-scroll");
}

static void check_sprite(void) {
    volatile ts_sprite_t *sfile = TS_FMAPS_SFILE(APERTURE);
    uint8_t row;

    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_HIDE_TSU);
    ts_video_set_scroll(0, 0);
    ts_memory_set_page3(0x58);
    for (row = 0; row < 8; ++row) {
        memset(w3 + 256u * row, 0x33, 4);
    }
    ts_video_set_sprite_page(0x58);

    ts_memory_set_page3(0x70);
    memset(w3, 0, 512);
    ts_fmaps_enable(APERTURE);
    ts_fmaps_write_words(sfile, w3, 256);
    ts_fmaps_write_words(sfile, &sprite, 3);
    ts_fmaps_disable();
    ZX_ASSERT(sfile[0].y == sprite.y && sfile[0].x == sprite.x && sfile[0].tile == 0);
    ZX_ASSERT(sfile[TS_SPRITE_COUNT - 1].y == 0);

    ts_video_set_border(0);
    ts_video_set_tsu_config(TS_TSU_SPRITES);
    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_256X192);
    zx_test_step_shot("sprite");
}

int main(void) {
    zx_test_init();
    ts_memory_set_cache(0);
    check_palette();
    check_sprite();
    zx_test_finish();
    return 0;
}
