/* XNX-specific TSConf rendering and resource placement. Game rules are in main.c. */
#include "game.h"
#include <im2.h>
#include <zx/audio.h>
#include <zx/interrupt.h>

typedef struct {
    uint8_t page, columns;
    uint16_t rows;
} image_t;
#include "assets.h"

#define SPRITES 0x70
#define LEVEL_PICTURE_PAGE 0x78
#define SCRATCH 0xd0

volatile uint8_t xnx_ticks;
static uint8_t tile_storage[33];
static uint8_t *tile_buffer;
static uint8_t selected_image, palette_id, brightness;
static uint8_t palette_dirty;
static const zx_ram_page_t screen_pages[ZX_DRAW_BUFFER_SLOTS] = {0x60, 0x68};
static uint8_t draw_slot, draw_dirty;
static uint8_t copy_whole_screen;
/* Right edge is exclusive. Zero marks a clean tile row. */
static uint8_t dirty_left[25], dirty_right[25];
static ts_sprite_t sprites[32];
static uint8_t sprite_count, sprites_enabled;
static uint8_t pause_previous, pause_edge;
static uint8_t music_enabled;
static zx_ram_lease_t pcm_lease;

static uint16_t shade(uint8_t value) {
    int8_t r = (value >> 4) + brightness - 3;
    int8_t g = ((value >> 2) & 3) + brightness - 3;
    int8_t b = (value & 3) + brightness - 3;
    if (r < 0) r = 0;
    if (g < 0) g = 0;
    if (b < 0) b = 0;
    if (r > 3) r = 3;
    if (g > 3) g = 3;
    if (b > 3) b = 3;
    return TS_PALETTE_RGB555((uint8_t)r << 3, (uint8_t)g << 3, (uint8_t)b << 3);
}

static void update_palette(void) {
    uint16_t colors[32];
    const uint8_t *source = palettes + ((uint16_t)palette_id << 4);
    uint8_t i;
    if (!palette_dirty) return;
    for (i = 0; i < 16; ++i) colors[i] = shade(source[i]);
    for (i = 16; i < 32; ++i) colors[i] = 0;
    for (i = 0; i < sizeof(sprite_colors); ++i) colors[17 + i] = shade(source[sprite_colors[i]]);
    ts_map_ram_page(ZX_WINDOW_3, SCRATCH);
    ts_video_upload_palette(ZX_WINDOW_3, 0, colors, 32);
    palette_dirty = 0;
}

void xnx_brightness(uint8_t value) {
    if (brightness != value) {
        brightness = value;
        palette_dirty = 1;
    }
}

void xnx_palette(uint8_t value) {
    if (palette_id != value) {
        palette_id = value;
        palette_dirty = 1;
    }
}

void xnx_select_image(uint8_t image) {
    selected_image = image;
}

static void mark_run(uint8_t x, uint8_t y, uint8_t tiles) {
    draw_dirty = 1;
    if (copy_whole_screen) return;
    if (!dirty_right[y] || x < dirty_left[y]) dirty_left[y] = x;
    if (x + tiles > dirty_right[y]) dirty_right[y] = x + tiles;
}

/* Both rasters use 256-byte scanlines. Eight scanlines at a tile-aligned Y
 * fit in one 16 KiB page, even when the next tile row starts a new page. */
static void copy_tile_run(uint8_t source, uint8_t sx, uint8_t sy, uint8_t destination, uint8_t x,
                          uint8_t y, uint8_t tiles) {
    ts_dma_transfer_t transfer;
    transfer.source.page = source + (sy >> 3);
    transfer.source.offset = ((uint16_t)(sy & 7) << 11) + ((uint16_t)sx << 2);
    transfer.destination.page = destination + (y >> 3);
    transfer.destination.offset = ((uint16_t)(y & 7) << 11) + ((uint16_t)x << 2);
    transfer.words_minus_one = tiles * 2 - 1;
    transfer.bursts_minus_one = 7;
    transfer.control = TS_DMA_COPY | TS_DMA_STRIDE_SOURCE | TS_DMA_STRIDE_DESTINATION;
    ts_dma_wait();
    ts_dma_start(&transfer);
    ts_dma_wait();
}

/* Expand the compact 8x8 tiles once, before the level starts. The 304x176
 * raster occupies three RAM pages with the TSConf 256-byte scanline stride. */
void xnx_prepare_picture(uint8_t picture) {
    const image_t *image = &images[picture];
    uint16_t tile = 0;
    uint8_t x, y;
    for (y = 0; y < image->rows; ++y)
        for (x = 0; x < image->columns; ++x)
            ts_video_draw_16c_tile(image->page, tile++, LEVEL_PICTURE_PAGE, x, y);
}

/* The level picture starts one tile from the left and two from the top. */
void xnx_draw_picture_run(uint8_t x, uint8_t y, uint8_t tiles) {
    copy_tile_run(LEVEL_PICTURE_PAGE, x, y, screen_pages[draw_slot], x + 1, y + 2, tiles);
    mark_run(x + 1, y + 2, tiles);
}

/* Whole opaque tiles use the SDK's banked tile path. Keyed tiles use its
 * nibble blitter after moving the source tile to resident memory. */
static void draw_tile(uint8_t x, uint8_t y, uint16_t tile, uint8_t keyed) {
    const image_t *image = images + selected_image;
    ts_window_lease_t lease;
    zx_bitmap4_t bitmap;
    if (x >= 40 || y >= 25 || tile >= (uint16_t)image->columns * image->rows) return;
    if (!keyed) {
        if (ts_video_draw_16c_tile(image->page, tile, screen_pages[draw_slot], x, y) == ZX_OK)
            mark_run(x, y, 1);
        return;
    }
    if (ts_window_acquire(ZX_WINDOW_3, image->page + (tile >> 9), &lease) != ZX_OK) return;
    memcpy(tile_buffer, (const uint8_t *)ZX_WINDOW_3 + ((tile & 511u) << 5), 32);
    ts_window_release(&lease);
    bitmap.pixels = tile_buffer;
    bitmap.width = bitmap.height = 8;
    bitmap.stride = 4;
    if (zx_blit4_key(&bitmap, (uint16_t)x * 8, (uint16_t)y * 8, 1) == ZX_OK) mark_run(x, y, 1);
}

void xnx_draw_tile(uint8_t x, uint8_t y, uint16_t tile) {
    draw_tile(x, y, tile, 0);
}
void xnx_draw_tile_key(uint8_t x, uint8_t y, uint16_t tile) {
    draw_tile(x, y, tile, 1);
}

void xnx_clear(uint8_t color) {
    if (ts_video_fill_16c_screen(screen_pages[draw_slot], color & 15) == ZX_OK) {
        draw_dirty = 1;
        copy_whole_screen = 1;
    }
}

void xnx_frame(void) {
    zx_wait_frame(&xnx_ticks);
    update_palette();
}

void xnx_delay(uint16_t frames) {
    while (frames--) xnx_frame();
}

/* Both buffers matched before drawing. Copying the gap between two
 * changes on a row also leaves those intervening pixels identical. */
static void copy_changed_rows(uint8_t source, uint8_t destination) {
    uint8_t y, left;
    for (y = 0; y < 25; ++y) {
        if (!dirty_right[y]) continue;
        left = dirty_left[y];
        copy_tile_run(source, left, y, destination, left, y, dirty_right[y] - left);
    }
}

void xnx_present(void) {
    xnx_frame();
    if (draw_dirty) {
        uint8_t next_slot = draw_slot ^ 1u;
        zx_ram_page_t displayed_page = screen_pages[draw_slot];
        zx_ram_page_t draw_page = screen_pages[next_slot];

        if (zx_select_draw_buffer(next_slot) != ZX_OK) return;
        if (zx_display_buffer(draw_slot) != ZX_OK) {
            zx_select_draw_buffer(draw_slot);
            return;
        }
        draw_slot = next_slot;

        if (copy_whole_screen)
            ts_video_copy_16c_screen(displayed_page, draw_page);
        else
            copy_changed_rows(displayed_page, draw_page);
        draw_dirty = 0;
        copy_whole_screen = 0;
        memset(dirty_right, 0, sizeof(dirty_right));
    }
    if (sprites_enabled) {
        memset(sprites + sprite_count, 0, sizeof(sprites) - sprite_count * sizeof(ts_sprite_t));
        ts_map_ram_page(ZX_WINDOW_3, SCRATCH);
        ts_video_upload_sprites(ZX_WINDOW_3, 0, sprites, 32);
        sprite_count = 0;
    }
}

void xnx_sprites_start(void) {
    memset(sprites, 0, sizeof(sprites));
    sprite_count = 0;
    sprites_enabled = 1;
    ts_map_ram_page(ZX_WINDOW_3, SCRATCH);
    ts_video_upload_sprites(ZX_WINDOW_3, 0, sprites, 32);
    ts_video_set_tsu_config(TS_TSU_SPRITES);
}

void xnx_sprites_stop(void) {
    sprites_enabled = 0;
    ts_video_set_tsu_config(0);
}

void xnx_sprite(uint8_t index, uint8_t x, uint8_t y, uint16_t image) {
    if (index >= 32 || image >= XNX_SPRITE_IMAGES) return;
    sprites[index].x = (1u << 9) | (uint16_t)x * 2;
    sprites[index].y = TS_SPRITE_ACTIVE | (1u << 9) | y;
    sprites[index].tile = 0x1000u | ((image >> 5) << 7) | ((image & 31) << 1);
    if (index >= sprite_count) sprite_count = index + 1;
}

uint8_t xnx_controls(void) {
    uint8_t value = joystick(1) | joystick(4);
    if (in_KeyPressed(0x017f)) value |= MOVE_FIRE;
    return value & 31;
}

void xnx_poll_input(void) {
    uint8_t down = in_KeyPressed(0x01df) != 0; /* P */
    pause_edge = down && !pause_previous;
    pause_previous = down;
}

uint8_t xnx_pause_pressed(void) {
    return pause_edge;
}

void xnx_audio_tick(void) {
    zx_ay_select_chip(ZX_AY_CHIP_1);
    if (music_enabled) zx_pt3_play();
    zx_ay_select_chip(ZX_AY_CHIP_0);
    zx_ayfx_frame();
}

void xnx_music(uint8_t track) {
    uint8_t irq = zx_interrupt_save_disable();
    zx_ay_select_chip(ZX_AY_CHIP_1);
    zx_pt3_init(music_modules[track]);
    zx_pt3_start();
    music_enabled = 1;
    zx_interrupt_restore(irq);
}

void xnx_music_stop(void) {
    uint8_t irq = zx_interrupt_save_disable();
    zx_ay_select_chip(ZX_AY_CHIP_1);
    zx_pt3_stop();
    music_enabled = 0;
    zx_interrupt_restore(irq);
}

void xnx_effect(uint8_t effect, int8_t volume) {
    zx_ayfx_play(effect, volume);
}

void xnx_sample(uint8_t sample) {
    zx_pcm8_banked_t descriptor;
    descriptor.first_page = sample ? 0xc2 : 0xc0;
    descriptor.offset = 0;
    descriptor.length = sample ? SAMPLE_MEOW_LENGTH : SAMPLE_START_LENGTH;
    descriptor.delay = 18;
    ts_set_cpu_speed_and_cache(ZX_CPU_3_5_MHZ, 0);
    zx_pcm8_play_banked(&descriptor, ZX_WINDOW_3, &pcm_lease);
    ts_set_cpu_speed_and_cache(ZX_CPU_14_MHZ, 0);
}

static void frame_hook(void) {
    ++xnx_ticks;
    xnx_audio_tick();
}

void xnx_init(void) {
    uint8_t slot;
    tile_buffer = (uint8_t *)(((uint16_t)tile_storage + 1u) & 0xfffeu);
    ts_set_cpu_speed_and_cache(ZX_CPU_14_MHZ, 0);
    ts_fdd_set_config(0);
    ts_io_set_interrupt_mask(0);
    ts_irq_set_frame_position(0, 0, 0);
    zx_set_video_mode(TS_VIDEO_16C_320X200 | TS_VIDEO_FLAG_HIDE_GFX | TS_VIDEO_FLAG_HIDE_TSU);
    ts_video_set_tsu_config(0);
    ts_video_set_border(0);
    ts_video_set_scroll(0, 0);
    ts_video_set_palette_select(0);
    ts_map_ram_page(ZX_WINDOW_3, SCRATCH);
    ts_video_upload_sprites(ZX_WINDOW_3, 0, NULL, TS_SPRITE_COUNT);
    ts_video_set_sprite_page(SPRITES);
    for (slot = 0; slot < ZX_DRAW_BUFFER_SLOTS; ++slot)
        zx_prepare_draw_buffer(slot, TS_VIDEO_16C_320X200, screen_pages[slot], NULL);
    ts_video_fill_16c_screen(screen_pages[1], 0);
    ts_video_copy_16c_screen(screen_pages[1], screen_pages[0]);
    draw_slot = 0;
    zx_select_draw_buffer(draw_slot);
    draw_dirty = 0;
    copy_whole_screen = 0;
    palette_id = 0;
    brightness = 0;
    palette_dirty = 1;
    update_palette();
    zx_ay_select_chip(ZX_AY_CHIP_1);
    zx_pt3_mute();
    zx_ay_select_chip(ZX_AY_CHIP_0);
    zx_ayfx_init(sound_effects);
    if (zx_display_buffer(1) == ZX_OK) zx_set_video_mode(TS_VIDEO_16C_320X200);
    /* The B9B9 ISR and BE00..BF00 vectors stay outside the linked BSS. The
     * SPG loader stub is at BC80 and the initial stack starts at BDB0. */
    memset((void *)0xbe00, 0xb9, 257);
    im2_CreateGenericISR(1, (void *)0xb9b9);
    im2_Init_fastcall((void *)0xbe00);
    im2_InstallISR(255, (void *)0xb9b9);
    im2_RegHookLast(255, frame_hook);
    ts_io_set_interrupt_mask(1);
    zx_interrupt_enable(1);
}
