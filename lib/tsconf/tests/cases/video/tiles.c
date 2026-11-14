#include <string.h>
#include <tsconf.h>
#include <zx_test.h>

#define W3_BASE 0xc000u
#define MAP_PAGE 0x60u
#define T0_ATLAS 0x48u
#define T1_ATLAS 0x58u
#define TILE_INDEX 65u
#define TILE_OFFSET 0x0804u

static uint8_t *const w3 = (uint8_t *)W3_BASE;
static const uint16_t palette[0x94] = {[0x41] = TS_PALETTE_RGB555(0, 0, 31),
                                       [0x61] = TS_PALETTE_RGB555(31, 0, 0),
                                       [0x81] = TS_PALETTE_RGB555(31, 31, 0),
                                       [0x92] = TS_PALETTE_RGB555(0, 31, 0),
                                       [0x93] = TS_PALETTE_RGB555(0, 31, 31)};

static void prepare_atlases(void) {
    uint8_t row;

    /* Tile 65 starts at atlas (8, 8), with 256 bytes per row and 2 pixels
     * per byte. Tile 0 provides a blue background on T0 and dots on T1. */
    ts_map_ram_page(ZX_WINDOW_3, T0_ATLAS);
    for (row = 0; row < 8; ++row) {
        memset(w3 + 256u * row, 0x11, 4);
        memset(w3 + TILE_OFFSET + 256u * row, 0x11, 4);
    }
    ts_map_ram_page(ZX_WINDOW_3, T1_ATLAS);
    for (row = 0; row < 8; ++row) {
        uint8_t *pixels = w3 + TILE_OFFSET + 256u * row;
        memset(w3 + 256u * row, 0, 4);
        memset(pixels, 0, 4);
        if (row < 3) {
            pixels[0] = 0x23;
        }
    }
    w3[0] = 0x10;
}

int main(void) {
    volatile uint8_t *map = w3;

    zx_test_init();
    ts_memory_set_cache(0);
    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_HIDE_TSU);
    ts_video_set_tsu_config(0);
    prepare_atlases();

    ts_map_ram_page(ZX_WINDOW_3, 0x70);
    ts_fmaps_enable(W3_BASE);
    ts_fmaps_write_words(TS_FMAPS_CRAM(W3_BASE), palette, sizeof(palette) / sizeof(*palette));
    ts_fmaps_disable();
    ts_video_set_border(0);
    /* T0 group 1 + local 2 -> bank 6. T1 group 2 + local 1 -> bank 9. */
    ts_video_set_palette_select(0x90);

    ts_video_set_tile_map_page(MAP_PAGE);
    ts_map_ram_page(ZX_WINDOW_3, MAP_PAGE);
    memset(w3, 0, 0x4000);
    ts_video_write_tile(map, 0, 35, 1, TS_TILE_ENTRY(TILE_INDEX, 2));
    ts_video_write_tile(map, 1, 66, 98,
                        TS_TILE_ENTRY(TILE_INDEX, 1) | TS_TILE_FLIP_X | TS_TILE_FLIP_Y);
    ZX_ASSERT(map[0x0145] == 0 && map[0x0146] == 0x41 && map[0x0147] == 0x20 && map[0x0148] == 0);
    ZX_ASSERT(map[0x2283] == 0 && map[0x2284] == 0x41 && map[0x2285] == 0xd0 && map[0x2286] == 0);
    zx_test_step_marker("tile-map-layout");

    ts_video_set_tile0_page(T0_ATLAS);
    ts_video_set_tile1_page(T1_ATLAS);
    /* T0 tile appears at (24, 10), T1 at (24, 8) after wrapping. */
    ts_video_set_tile0_scroll(0x0300, 0x03fe);
    ts_video_set_tile1_scroll(0x01f8, 0x0108);
    ts_video_set_tsu_config(TS_TSU_TILE0 | TS_TSU_TILE1);
    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_256X192);
    zx_test_step_shot("tile-layers");

    ts_video_set_tsu_config(TS_TSU_TILE0 | TS_TSU_TILE0_INDEX0 | TS_TSU_TILE1 |
                            TS_TSU_TILE1_INDEX0);
    zx_test_step_shot("tile-index-zero");
    zx_test_finish();
    return 0;
}
