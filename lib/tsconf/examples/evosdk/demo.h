#ifndef EVOSDK_DEMO_H
#define EVOSDK_DEMO_H

#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <input.h>
#include <games.h>
#include <intrinsic.h>
#include <tsconf.h>

typedef struct {
    uint8_t page;
    uint16_t offset;
    uint8_t rows;
} resource_chunk_t;
typedef struct {
    const resource_chunk_t *chunks;
    uint8_t count, row_bytes;
} image_resource_t;
#include "resources.h"

#if RESOURCE_PACKED
#include <compress/zx0.h>
/* C BSS may start at an odd address. DMA drops address bit 0, so reserve
 * one padding byte and align the decoded pixels before passing them to DMA. */
static uint8_t unpack_storage[2049];
#define unpack_buffer ((uint8_t *)(((uint16_t)unpack_storage + 1u) & 0xfffeu))
#endif

enum { SCREEN_PAGE = 0x40, OTHER_SCREEN_PAGE = 0x48, ATLAS_PAGE = 0xb0, SCRATCH_PAGE = 0xc0 };
#define W3 0xc000u

/* BASIC 48 supplies IM1, ROM and system variables in W0/W1. All demo code,
 * constants and BSS stay in W2; the incoming BASIC stack stays below 8000h.
 * Only W3 is borrowed. These demos own DMA, TSU, FMAPS and the listed pages.
 * Start in BASIC 48, with DOS/FDDVirt disabled and CPU caching off. */
static uint8_t saved_w3;
static uint8_t saved_border;

static void demo_begin(void) {
    saved_w3 = ts_memory_get_page3();
    saved_border = (*(const uint8_t *)0x5c48u >> 3) & 7;
    ts_video_set_config(TS_VIDEO_16C | TS_VIDEO_320X200 | TS_VIDEO_HIDE_GFX | TS_VIDEO_HIDE_TSU);
    ts_video_set_tsu_config(0);
    ts_video_set_scroll(0, 0);
    ts_video_set_palette_select(0);
    ts_video_set_border(0);
    ts_map_ram_page(ZX_WINDOW_3, SCRATCH_PAGE);
}

/* Frame INT is the only enabled source in the BASIC 48 launch profile. */
static void frame(void) {
    intrinsic_halt();
}

static void demo_end(void) {
    ts_dma_wait();
    ts_video_set_tsu_config(0);
    ts_fmaps_disable();
    ts_map_ram_page(ZX_WINDOW_3, saved_w3);
    ts_video_set_palette_select(15);
    ts_video_set_page(5);
    ts_video_set_scroll(0, 0);
    ts_video_set_config(TS_VIDEO_ZX | TS_VIDEO_256X192);
    ts_video_set_border(240u + saved_border);
}

/* Use z88dk's existing key scanner; CAPS SHIFT + SPACE returns to BASIC. */
static uint8_t quit(void) {
    return in_KeyPressed(0x81feu) && in_KeyPressed(0x017fu);
}

/* games.h uses the same direction bits as evosdk. Merge the existing
 * Kempston and Cursor implementations; Space also acts as Fire. */
static uint8_t controls(void) {
    uint8_t value = (uint8_t)(joystick(1) | joystick(4));
    if (in_KeyPressed(0x017fu)) value |= MOVE_FIRE;
    return value & 31u;
}

/* evosdk's seven brightness steps subtract/add one RGB222 level, clipping
 * channels to 0..3. Normal brightness is 3. Convert to TSConf RGB555 with
 * the same 0,8,16,24 levels as the original TSConf palette table. */
static void set_palette(const uint8_t *source, uint8_t bank, int8_t brightness) {
    uint16_t colors[16];
    uint8_t i;
    for (i = 0; i < 16; ++i) {
        int8_t r = (source[i] >> 4) + brightness - 3;
        int8_t g = ((source[i] >> 2) & 3) + brightness - 3;
        int8_t b = (source[i] & 3) + brightness - 3;
        if (r < 0) r = 0;
        if (g < 0) g = 0;
        if (b < 0) b = 0;
        if (r > 3) r = 3;
        if (g > 3) g = 3;
        if (b > 3) b = 3;
        colors[i] = TS_PALETTE_RGB555((uint8_t)r << 3, (uint8_t)g << 3, (uint8_t)b << 3);
    }
    ts_video_upload_palette(ZX_WINDOW_3, 16u * bank, colors, 16);
}

/* Unpack at most 2 KiB at a time using z88dk's existing ZX0 decoder.
 * Compressed source occupies W3; code, stack and output remain resident.
 * DMA reads the W2 buffer's physical address and writes rows with stride 256.
 * The raw build bypasses decompression and copies directly from asset banks.
 * DMA is idle before the buffer is reused; source and destination never alias. */
static void upload(const image_resource_t *image, uint8_t destination) {
    ts_dma_transfer_t transfer;
    uint8_t i, y = 0;
    transfer.words_minus_one = image->row_bytes / 2 - 1;
    transfer.control = TS_DMA_COPY | TS_DMA_STRIDE_DESTINATION;
    ts_dma_wait();
    for (i = 0; i < image->count; ++i) {
        const resource_chunk_t *chunk = image->chunks + i;
#if RESOURCE_PACKED
        ts_map_ram_page(ZX_WINDOW_3, chunk->page);
        dzx0_standard((void *)(W3 + chunk->offset), unpack_buffer);
        ts_map_ram_page(ZX_WINDOW_3, SCRATCH_PAGE);
        transfer.source.page = ts_memory_get_page2();
        transfer.source.offset = (uint16_t)unpack_buffer & 0x3fffu;
#else
        transfer.source.page = chunk->page;
        transfer.source.offset = chunk->offset;
#endif
        transfer.destination.offset = (uint16_t)(y & 63) << 8;
        transfer.destination.page = destination + (y >> 6);
        transfer.bursts_minus_one = chunk->rows - 1;
        ts_dma_start(&transfer);
        ts_dma_wait();
        y += chunk->rows;
    }
}

static void show_screen(uint8_t page) {
    ts_video_set_page(page);
    ts_video_set_config(TS_VIDEO_16C | TS_VIDEO_320X200);
}

/* One hardware descriptor per 16x16 source sprite; palette bank 1 keeps
 * transparent zero independent of the background's opaque color zero. */
static void sprites_begin(void) {
    ts_video_upload_sprites(ZX_WINDOW_3, 0, NULL, TS_SPRITE_COUNT);
    ts_video_set_sprite_page(ATLAS_PAGE);
    ts_video_set_tsu_config(TS_TSU_SPRITES);
}

static void sprites_write(const ts_sprite_t *sprites, uint8_t count) {
    ts_video_upload_sprites(ZX_WINDOW_3, 0, sprites, count);
}

#endif
