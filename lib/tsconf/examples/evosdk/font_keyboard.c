/* Adapted from the public-domain evosdk example_font_keyboard.
 * Keep the original colored 8x8 font, 38-column wrapping and key priority.
 * Keyboard scanning is provided by z88dk, glyph copies by TSConf DMA. */
#include "demo.h"
#include "resources.h"

static uint8_t output_x = 1, output_y = 1;
static const char characters[] = "0123456789abcdefghijklmnopqrstuvwxyz \r";
static uint16_t scancodes[38];
static uint8_t previous[38];

static void put_char(uint8_t code) {
    if (code >= ' ' && code <= 'Z') {
        uint8_t tile = code - ' ';
        ts_dma_transfer_t transfer;
        transfer.source.offset = (uint16_t)(tile >> 4) * 2048u + (tile & 15) * 4u;
        transfer.source.page = ATLAS_PAGE;
        transfer.destination.offset = (uint16_t)(output_y & 7) * 2048u + output_x * 4u;
        transfer.destination.page = SCREEN_PAGE + (output_y >> 3);
        transfer.words_minus_one = 1;
        transfer.bursts_minus_one = 7;
        transfer.control = TS_DMA_COPY | TS_DMA_STRIDE_SOURCE | TS_DMA_STRIDE_DESTINATION;
        ts_dma_wait();
        ts_dma_start(&transfer);
        ts_dma_wait();
    }
    ++output_x;
    if (output_x == 39 || code == '\n') {
        output_x = 1;
        if (++output_y == 24) output_y = 1;
    }
}

int main(void) {
    uint8_t i, key, down;
    const char *greeting = "HELLO WORLD\n\n";
    demo_begin();
    upload(&image_resources[0], ATLAS_PAGE);
    /* Current SDK clear handles packed page mapping; no duplicate blitter. */
    if (ts_video_set_mode(TS_VIDEO_16C | TS_VIDEO_320X200 | TS_VIDEO_HIDE_GFX, SCREEN_PAGE, 0) !=
        ZX_OK) {
        demo_end();
        return 1;
    }
    zx_set_paper(1);
    if (zx_console_clear() != ZX_OK) {
        demo_end();
        return 1;
    }
    set_palette(image_palettes[0], 0, 3);
    for (i = 0; i < 38; ++i) scancodes[i] = in_LookupKey(characters[i]);
    while (*greeting) put_char(*greeting++);
    show_screen(SCREEN_PAGE);
    while (!quit()) {
        key = 255;
        for (i = 0; i < 38; ++i) {
            down = in_KeyPressed(scancodes[i]) != 0;
            if (down && !previous[i]) key = characters[i];
            previous[i] = down;
        }
        if (key >= 'a' && key <= 'z') key -= 'a' - 'A';
        if (key == '\r') key = '\n';
        if (key != 255) put_char(key);
        frame();
    }
    demo_end();
    return 0;
}
