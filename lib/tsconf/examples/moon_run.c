#include <string.h>
#include <tsconf.h>

#define W3 0xc000u

enum { ATLAS_PAGE = 0x48, SHIP_PAGE = 0x58, MAP_PAGE = 0x60, SCRATCH_PAGE = 0x70 };
enum { SKY, STAR, DIM_STAR, SOIL, TERRAIN = 64, EARTH = 192 };

static const volatile uint8_t *const basic_frames = (const volatile uint8_t *)0x5c78u;
static uint8_t *const work = (uint8_t *)W3;

static const uint16_t palette[] = {
    TS_PALETTE_RGB555(0, 0, 0),    TS_PALETTE_RGB555(2, 3, 9),    TS_PALETTE_RGB555(23, 26, 31),
    TS_PALETTE_RGB555(12, 13, 18), TS_PALETTE_RGB555(20, 21, 27), TS_PALETTE_RGB555(8, 9, 13),
    TS_PALETTE_RGB555(22, 21, 29), TS_PALETTE_RGB555(31, 24, 12), TS_PALETTE_RGB555(12, 24, 31),
    TS_PALETTE_RGB555(4, 10, 22),  TS_PALETTE_RGB555(5, 17, 29),  TS_PALETTE_RGB555(6, 19, 15),
    TS_PALETTE_RGB555(16, 25, 20), TS_PALETTE_RGB555(17, 27, 31), TS_PALETTE_RGB555(29, 30, 31),
    TS_PALETTE_RGB555(10, 12, 20)};

/* Each group of four bytes is one row of eight packed 4bpp pixels. */
static const uint8_t tiles[][8][4] = {[SKY] = {{0x11, 0x11, 0x11, 0x11},
                                               {0x11, 0x11, 0x11, 0x11},
                                               {0x11, 0x11, 0x11, 0x11},
                                               {0x11, 0x11, 0x11, 0x11},
                                               {0x11, 0x11, 0x11, 0x11},
                                               {0x11, 0x11, 0x11, 0x11},
                                               {0x11, 0x11, 0x11, 0x11},
                                               {0x11, 0x11, 0x11, 0x11}},
                                      [STAR] = {{0x11, 0x11, 0x11, 0x11},
                                                {0x11, 0x11, 0x11, 0x11},
                                                {0x11, 0x12, 0x11, 0x11},
                                                {0x11, 0x22, 0x21, 0x11},
                                                {0x11, 0x12, 0x11, 0x11},
                                                {0x11, 0x11, 0x11, 0x11},
                                                {0x11, 0x11, 0x11, 0x11},
                                                {0x11, 0x11, 0x11, 0x11}},
                                      [DIM_STAR] = {{0x11, 0x11, 0x11, 0x11},
                                                    {0x11, 0x11, 0x11, 0x11},
                                                    {0x11, 0x11, 0x11, 0x11},
                                                    {0x11, 0x11, 0x1f, 0x11},
                                                    {0x11, 0x11, 0x11, 0x11},
                                                    {0x11, 0x11, 0x11, 0x11},
                                                    {0x11, 0x11, 0x11, 0x11},
                                                    {0x11, 0x11, 0x11, 0x11}},
                                      [SOIL] = {{0x55, 0x55, 0x55, 0x55},
                                                {0x55, 0x55, 0x55, 0x55},
                                                {0x53, 0x35, 0x55, 0x55},
                                                {0x55, 0x55, 0x55, 0x55},
                                                {0x55, 0x55, 0x55, 0x35},
                                                {0x55, 0x55, 0x55, 0x55},
                                                {0x55, 0x55, 0x55, 0x55},
                                                {0x55, 0x55, 0x55, 0x55}}};

/* Terrain control points are 16 pixels apart. The last closes the 512px map. */
static const uint8_t horizon[] = {139, 137, 127, 111, 120, 132, 140, 146, 148, 145, 134,
                                  125, 119, 126, 142, 144, 135, 131, 118, 104, 116, 133,
                                  139, 145, 150, 146, 138, 128, 122, 130, 141, 142, 139};

/* One palette digit per pixel, two pixels per byte in the uploaded atlas. */
static const char ship_art[16][17] = {
    "0000000000000000", "0000000000000000", "0000000060000000", "0000000666000000",
    "0000006688600000", "0000066888860000", "0006666688866000", "0766666666666600",
    "7776666666666660", "0766666333336600", "0006666333366000", "0000666333660000",
    "0000066666000000", "0000006600000000", "0000000000000000", "0000000000000000"};

static uint8_t terrain_row[64];

static uint8_t terrain_pixel(uint8_t y, uint8_t height) {
    if (y < height) return 0;
    if (y == height) return 4;
    if (y < height + 3) return 3;
    return 5;
}

static void build_terrain(void) {
    uint8_t column, x, row;

    for (column = 0; column < 64; ++column) {
        uint8_t heights[8];
        uint8_t start = horizon[column >> 1];
        int8_t slope = horizon[(column >> 1) + 1] - start;
        uint8_t base;

        for (x = 0; x < 8; ++x) heights[x] = start + slope * (8 * (column & 1) + x) / 16;
        base = heights[0] < heights[7] ? heights[0] : heights[7];
        terrain_row[column] = base >> 3;
        base &= 0xf8;

        /* Each column's eight heights fit in two vertically adjacent tiles. */
        for (row = 0; row < 16; ++row) {
            uint8_t *pixels = work + 256u * (8 + row) + 4u * column;
            for (x = 0; x < 8; x += 2) {
                *pixels++ = (terrain_pixel(base + row, heights[x]) << 4) |
                            terrain_pixel(base + row, heights[x + 1]);
            }
        }
    }
}

static uint8_t earth_pixel(int16_t x, int16_t y) {
    int16_t distance = x * x + y * y;
    uint8_t shade = x + y > 9;

    if (distance > 225) return 1;
    if (distance > 192) return shade ? 9 : 13;
    if ((y == -8 && x > -12 && x < 2) || (y == 5 && x > 0 && x < 11)) return 14;
    if ((x + y > -15 && x + y < 0 && y > -7 && y < 2) ||
        (x - y > -6 && x - y < 4 && y >= 2 && y < 11))
        return shade ? 11 : 12;
    return shade ? 9 : 10;
}

static void build_moon(void) {
    uint16_t stars = 0xace1;
    uint8_t row, column, tile, x;

    ts_memory_set_page3(ATLAS_PAGE);
    for (tile = 0; tile < sizeof(tiles) / sizeof(*tiles); ++tile) {
        for (row = 0; row < 8; ++row) memcpy(work + 256u * row + 4 * tile, tiles[tile][row], 4);
    }
    build_terrain();
    for (row = 0; row < 32; ++row) {
        uint8_t *pixels = work + 256u * (24 + row);
        for (x = 0; x < 32; x += 2)
            *pixels++ = (earth_pixel(x - 15, row - 15) << 4) | earth_pixel(x - 14, row - 15);
    }

    ts_memory_set_page3(SHIP_PAGE);
    for (row = 0; row < 16; ++row) {
        uint8_t *pixels = work + 256u * row;
        for (x = 0; x < 16; x += 2)
            *pixels++ = ((ship_art[row][x] - '0') << 4) | (ship_art[row][x + 1] - '0');
    }

    ts_memory_set_page3(MAP_PAGE);
    memset(work, 0, 0x4000);
    for (column = 0; column < 64; ++column) {
        for (row = 0; row < 24; ++row) {
            /* Fixed-seed LFSR scatters points without a repeating diagonal. */
            stars = (stars >> 1) ^ ((stars & 1) ? 0xb400u : 0);
            /* Read separated taps so a run of zero bits cannot stack stars. */
            if ((stars & 0x9420u) == 0) {
                tile = (stars & 0x2800u) == 0 ? STAR : DIM_STAR;
                ts_video_write_tile(work, 0, column, row, TS_TILE_ENTRY(tile, 0));
            }
        }
        row = terrain_row[column];
        ts_video_write_tile(work, 1, column, row++, TS_TILE_ENTRY(TERRAIN + column, 0));
        ts_video_write_tile(work, 1, column, row++, TS_TILE_ENTRY(TERRAIN + 64 + column, 0));
        for (; row < 24; ++row) {
            uint16_t flip = ((stars >> (row & 7)) & 3u) << 14;
            ts_video_write_tile(work, 1, column, row, TS_TILE_ENTRY(SOIL, 0) | flip);
        }
    }
    for (row = 0; row < 4; ++row)
        for (column = 0; column < 4; ++column)
            ts_video_write_tile(work, 0, 24 + column, 3 + row,
                                TS_TILE_ENTRY(EARTH + 64u * row + column, 0));
}

static void show_ship(uint16_t y) {
    ts_sprite_t ship = {TS_SPRITE_ACTIVE | TS_SPRITE_LEAP | (1u << 9) | y, (1u << 9) | 66u, 0};

    /* Slot 0 is an inactive LEAP, putting the ship above tile layer 0. */
    ts_fmaps_enable(W3);
    ts_fmaps_write_words(TS_FMAPS_SFILE(W3) + 1, &ship, 3);
    ts_fmaps_disable();
}

int main(void) {
    const ts_sprite_t skip_layer = {TS_SPRITE_LEAP, 0, 0};
    uint8_t saved_w3 = ts_memory_get_page3();
    uint16_t frame;
    zx_status_t status = ZX_OK;

    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_HIDE_TSU | TS_VIDEO_256X192);
    ts_video_set_tsu_config(0);
    build_moon();

    ts_memory_set_page3(SCRATCH_PAGE);
    memset(work + 0x400, 0, TS_SPRITE_COUNT * sizeof(ts_sprite_t));
    ts_fmaps_enable(W3);
    ts_fmaps_write_words(TS_FMAPS_CRAM(W3), palette, sizeof(palette) / sizeof(*palette));
    ts_fmaps_write_words(TS_FMAPS_SFILE(W3), work + 0x400, TS_SPRITE_COUNT * 3);
    ts_fmaps_write_words(TS_FMAPS_SFILE(W3), &skip_layer, 3);
    ts_fmaps_disable();

    ts_video_set_tile_map_page(MAP_PAGE);
    ts_video_set_tile0_page(ATLAS_PAGE);
    ts_video_set_tile1_page(ATLAS_PAGE);
    ts_video_set_sprite_page(SHIP_PAGE);
    ts_video_set_palette_select(0);
    zx_set_border_color(COLOR_BLACK);
    ts_video_set_tile0_scroll(0, 0);
    ts_video_set_tile1_scroll(0, 0);
    show_ship(78);
    ts_video_set_tsu_config(TS_TSU_TILE0 | TS_TSU_TILE0_INDEX0 | TS_TSU_TILE1 | TS_TSU_SPRITES);
    ts_video_set_config(TS_VIDEO_HIDE_GFX | TS_VIDEO_256X192);

    for (frame = 0; frame < 300; ++frame) {
        uint8_t phase = (uint8_t)frame & 63;
        status = zx_wait_frame(basic_frames);
        if (status != ZX_OK) break;
        ts_video_set_tile0_scroll(frame / 2, 0);
        ts_video_set_tile1_scroll(3 * frame, 0);
        if (phase & 32) phase ^= 63;
        show_ship(78 + phase / 2);
    }

    ts_video_set_tsu_config(0);
    ts_memory_set_page3(saved_w3);
    ts_video_set_palette_select(15);
    ts_video_set_page(5);
    ts_video_set_scroll(0, 0);
    ts_video_set_config(TS_VIDEO_ZX | TS_VIDEO_256X192);
    zx_set_border_color(COLOR_WHITE);
    return status;
}
