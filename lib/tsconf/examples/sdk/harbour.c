#include <tsconf.h>

enum { CANVAS_PAGE = 0x40, SCRATCH_PAGE = 0x70, W3 = 0xc000 };
enum { SKY = 32, WATER = SKY + 16, SUN = WATER + 8, GOLD, LIGHT, INK };

static const volatile uint8_t *const basic_frames = (const volatile uint8_t *)0x5c78u;

static void load_palette(uint8_t saved_w3) {
    uint16_t palette[INK - SKY + 1];
    uint8_t i;

    for (i = 0; i < 16; ++i) palette[i] = TS_PALETTE_RGB555(4 + i + i / 2, 3 + i, 15 + i / 3);
    for (i = 0; i < 8; ++i) palette[WATER - SKY + i] = TS_PALETTE_RGB555(5, 12 - i, 24 - i);
    palette[SUN - SKY] = TS_PALETTE_RGB555(31, 23, 9);
    palette[GOLD - SKY] = TS_PALETTE_RGB555(26, 15, 8);
    palette[LIGHT - SKY] = TS_PALETTE_RGB555(31, 29, 23);
    palette[INK - SKY] = TS_PALETTE_RGB555(2, 2, 7);

    /* Use scratch RAM behind FMAPS. Leave the BASIC palette in bank F alone. */
    ts_map_ram_page(ZX_WINDOW_3, SCRATCH_PAGE);
    ts_video_upload_palette(ZX_WINDOW_3, SKY, palette, sizeof(palette) / sizeof(*palette));
    ts_map_ram_page(ZX_WINDOW_3, saved_w3);
}

static zx_status_t paint_harbour(void) {
    int16_t y, half_width;
    uint8_t band;
    zx_status_t status = zx_graphics_begin();
    if (status != ZX_OK) return status;

    for (band = 0; band < 16; ++band) {
        zx_set_ink(SKY + band);
        zx_draw_fill_rect(0, 6 * band, 256, 6);
    }
    for (band = 0; band < 8; ++band) {
        zx_set_ink(WATER + band);
        zx_draw_fill_rect(0, 96 + 12 * band, 256, 12);
    }

    zx_set_ink(SUN);
    for (y = -22; y <= 22; ++y) {
        half_width = 22;
        while (half_width * half_width + y * y > 22 * 22) --half_width;
        zx_draw_hline(174 - half_width, 174 + half_width, 72 + y);
    }
    zx_set_ink(GOLD);
    for (y = 99; y < 152; y += 4) {
        half_width = 8 + (y - 99) / 2;
        zx_draw_hline(173 - half_width + (y & 7), 175 + half_width, y);
    }

    /* Rig and sails in front of the light, followed by the dark hull. */
    zx_set_ink(LIGHT);
    for (y = 99; y < 145; ++y) zx_draw_hline(98 - (y - 98) / 2, 98, y);
    for (y = 111; y < 145; ++y) zx_draw_hline(102, 102 + (y - 109) / 2, y);
    zx_set_ink(INK);
    zx_draw_vline(100, 95, 152);
    for (y = 148; y < 157; ++y) zx_draw_hline(71 + y - 148, 129 - y + 148, y);

    status = zx_graphics_end();
    if (status != ZX_OK) return status;
    zx_set_ink(LIGHT);
    status = zx_console_set_font(&zx_font5);
    if (status != ZX_OK) return status;

    zx_console_set_font(&zx_font5);
    return zx_console_draw_op(2, 1, "HARBOUR / LAST LIGHT", ZX_TEXT_TRANSPARENT);
}

int main(void) {
    const uint8_t mode = TS_VIDEO_256C | TS_VIDEO_256X192 | TS_VIDEO_HIDE_TSU;
    uint8_t saved_w3 = ts_memory_get_page3();
    zx_status_t status;

    status = ts_video_set_mode(mode | TS_VIDEO_HIDE_GFX, CANVAS_PAGE, 0);
    if (status != ZX_OK) return status;
    load_palette(saved_w3);
    ts_video_set_scroll(0, 0);
    ts_video_set_palette_select(0);
    status = paint_harbour();
    if (status == ZX_OK) {
        zx_set_border_color(COLOR_BLACK);
        ts_video_set_config(mode);
        status = zx_wait_frames(basic_frames, 250);
    }

    ts_map_ram_page(ZX_WINDOW_3, saved_w3);
    ts_video_set_page(5);
    ts_video_set_palette_select(15);
    ts_video_set_config(TS_VIDEO_ZX | TS_VIDEO_256X192);
    zx_set_border_color(COLOR_WHITE);
    return status;
}
