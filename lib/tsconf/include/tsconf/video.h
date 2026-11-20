#ifndef TSCONF_VIDEO_H
#define TSCONF_VIDEO_H

#include <stdint.h>
#include <zx/memory.h>
#include <zx/video.h>

/* Choose one complete mode. The raster is part of its name.
 * TEXT names use the displayed pixel width, twice the raster width.
 * OR in TS_VIDEO_FLAG_* to hide layers. */
#define TS_VIDEO_ZX_256X192 ZX_VIDEO_ZX_256
#define TS_VIDEO_ZX_320X200 0x140u
#define TS_VIDEO_ZX_320X240 0x180u
#define TS_VIDEO_ZX_360X288 0x1c0u

#define TS_VIDEO_16C_256X192 0x101u
#define TS_VIDEO_16C_320X200 0x141u
#define TS_VIDEO_16C_320X240 0x181u
#define TS_VIDEO_16C_360X288 0x1c1u

#define TS_VIDEO_256C_256X192 0x102u
#define TS_VIDEO_256C_320X200 0x142u
#define TS_VIDEO_256C_320X240 0x182u
#define TS_VIDEO_256C_360X288 0x1c2u

#define TS_VIDEO_TEXT_512X192 0x103u
#define TS_VIDEO_TEXT_640X200 0x143u
#define TS_VIDEO_TEXT_640X240 0x183u
#define TS_VIDEO_TEXT_720X288 0x1c3u

#define TS_VIDEO_FLAG_HIDE_TSU 0x110u /* Hide tile and sprite output. */
#define TS_VIDEO_FLAG_HIDE_GFX 0x120u /* Hide the base bitmap or text layer. */

/* zx_get_video_mode reports the last mode written by the SDK.
 * zx_set_video_mode changes VConfig and leaves the display page, CPU mappings
 * and draw surface alone. Prepare an aligned display page for the new layout
 * before exposing it. Serialize video changes with drawing. */

#define TS_TSU_TILE0_INDEX0 0x04u
#define TS_TSU_TILE1_INDEX0 0x08u
#define TS_TSU_TILE0 0x20u
#define TS_TSU_TILE1 0x40u
#define TS_TSU_SPRITES 0x80u

#define TS_TILE_FLIP_X 0x4000u
#define TS_TILE_FLIP_Y 0x8000u
/* The index is 0..4095 and the local palette is 0..3. OR in flip flags. */
#define TS_TILE_ENTRY(index, palette) ((uint16_t)((index) | ((uint16_t)(palette) << 12)))

/* Each channel takes a value in 0..31. */
#define TS_PALETTE_RGB555(r, g, b)                                                                 \
    ((uint16_t)(((uint16_t)(r) << 10) | ((uint16_t)(g) << 5) | (uint16_t)(b)))
#define TS_PALETTE_VDAC_MODE 0x8000u

#define TS_FMAPS_CRAM(base) ((volatile uint16_t *)(uintptr_t)(base))
#define TS_FMAPS_SFILE(base) ((volatile ts_sprite_t *)((uintptr_t)(base) + 0x200u))

/* SFILE holds 85 descriptors. Compose Y and X with a 9-bit coordinate and
 * (size in units of 8 pixels - 1) in bits 11:9. The last word holds the
 * 12-bit atlas tile index and the palette bank in bits 15:12. */
typedef struct {
    uint16_t y;
    uint16_t x;
    uint16_t tile;
} ts_sprite_t;

#define TS_SPRITE_COUNT 85u
#define TS_SPRITE_ACTIVE 0x2000u /* Y word */
#define TS_SPRITE_LEAP 0x4000u   /* Y word */
#define TS_SPRITE_FLIP 0x8000u   /* Y or X word */

/* Upload count descriptors starting at first (first+count <= TS_SPRITE_COUNT).
 * NULL source clears the selected descriptors; zero count does nothing.
 * The first 4 KiB of window (ZX_WINDOW_0..3) are used temporarily for FMAPS.
 * Window is a CPU window, not a physical RAM page. Map disposable writable
 * RAM there beforehand: underlying RAM can be overwritten by these stores.
 * Code, stack and non-NULL source must remain outside that 4 KiB aperture;
 * source must be readable for the whole transfer without address wrap.
 * Caller owns FMAPS (disabled on entry) and excludes NMI/DMA writers to the
 * internal files and paging changes. INT is disabled for the upload and its
 * previous state restored. FMAPS is disabled on return; RAM mapping is unchanged.
 * Schedule updates during blanking or hide the sprite layer to avoid tearing.
 * Invalid window/range returns ZX_INVALID_ARGUMENT before any hardware write. */
zx_status_t ts_video_upload_sprites(zx_window_t window, uint8_t first, const ts_sprite_t *source,
                                    uint8_t count);

/* As ts_video_upload_sprites, but upload RGB555/VDAC palette words to CRAM.
 * first+count <= 256; NULL source clears entries to zero (black).
 * Count is in colors, not bytes. Schedule writes to a live palette as needed. */
zx_status_t ts_video_upload_palette(zx_window_t window, uint8_t first, const uint16_t *source,
                                    uint16_t count);

/* DMA helpers for a 320x200 16-color bitmap. Source and destination screen
 * bases are 8-page aligned. Tile coordinates are 0..39, 0..24. Functions
 * wait for the DMA engine and leave CPU page mappings intact. The caller
 * keeps the destination hidden until drawing is complete. */
zx_status_t ts_video_copy_16c_screen(uint8_t source_page, uint8_t destination_page);
zx_status_t ts_video_copy_16c_tile(uint8_t source_page, uint8_t destination_page, uint8_t x,
                                   uint8_t y);
zx_status_t ts_video_fill_16c_screen(uint8_t page, uint8_t color);
/* Source contains packed 8x8 tiles, 32 bytes per tile across consecutive
 * physical pages. The source base may be any page; the destination is an
 * aligned screen base. */
zx_status_t ts_video_draw_16c_tile(uint8_t source_page, uint16_t tile, uint8_t destination_page,
                                   uint8_t x, uint8_t y);

/* Shared surface operations use page0 as the physical base and require
 * page1 == 0. For ZX and text, pass one CPU window address for drawing.
 * For packed modes, pass NULL for both windows. The physical base must be
 * aligned to 8 pages for 16 colors and 16 pages for 256 colors. */
/* Report the native TSConf raster area in pixels for the last VConfig set
 * by this library. Hardware text doubles the horizontal pixel count.
 * With TSCONF_VIDEO_60HZ=1 at library build time, 360x288 has 240 lines.
 * Return ZX_INVALID_ARGUMENT for NULL or ZX_NOT_INITIALIZED for an unknown
 * VConfig. Leave the output untouched on error. Blanking and scrolling do
 * not change the size. */
zx_status_t ts_video_get_raster_size(zx_video_size_t *size) __z88dk_fastcall;

/* Write PalSel. Bits 3:0 select the graphics palette bank. Bits 5:4
 * and 7:6 select the palette groups for tile layers 0 and 1. */
void ts_video_set_palette_select(uint8_t select) __z88dk_fastcall;

/* Set the full eight-bit CRAM index of the border. */
void ts_video_set_border(uint8_t index) __z88dk_fastcall;

/* Write TSConfig to control the sprite and tile layers. */
void ts_video_set_tsu_config(uint8_t config) __z88dk_fastcall;

/* Select the physical RAM page that holds both 64×64 tile maps. */
void ts_video_set_tile_map_page(uint8_t page) __z88dk_fastcall;

/* Select the physical base page of each 512×512 packed 4bpp tile atlas.
 * Align each base to 8 pages. The layers may share an atlas. */
void ts_video_set_tile0_page(uint8_t page) __z88dk_fastcall;
void ts_video_set_tile1_page(uint8_t page) __z88dk_fastcall;

/* Select the physical base page of the sprite atlas, aligned to 8 pages. */
void ts_video_set_sprite_page(uint8_t page) __z88dk_fastcall;

/* Write the low nine bits of each graphics offset. The four writes can span
 * a raster boundary. Set offsets during blanking or while graphics is hidden
 * if the change must be invisible. Use zero offsets for ordinary ZX/text. */
void ts_video_set_scroll(uint16_t x, uint16_t y);

/* Write the low nine bits of each tile layer's X and Y offsets. Set the
 * offsets during blanking or with the layer hidden to avoid a split update. */
void ts_video_set_tile0_scroll(uint16_t x, uint16_t y);
void ts_video_set_tile1_scroll(uint16_t x, uint16_t y);

/* Write a descriptor into the tile map. Map the selected TMPage in a
 * writable 16 KiB CPU window and pass that window's base as map.
 * The layer uses bit 0 and coordinates wrap modulo 64. For a live map,
 * account for tile-map prefetch and the two separate byte stores. */
void ts_video_write_tile(volatile void *map, uint8_t layer, uint8_t column, uint8_t row,
                         uint16_t entry);

/* Low-level mapping at any 4 KiB-aligned CPU address, not a physical RAM page.
 * Prefer ts_video_upload_sprites/palette with ZX_WINDOW_* for ordinary uploads.
 * Use disposable backing memory and keep code, data and stack clear of the aperture. */
void ts_fmaps_enable(uint16_t base) __z88dk_fastcall;
void ts_fmaps_disable(void);

/* Copy count little-endian words (0..256) to CRAM or SFILE in an already
 * enabled FMAPS aperture, with low byte first. Use an even destination and
 * stay within the selected region. Source and destination must not overlap.
 * Caller owns FMAPS and excludes DMA to internal files and interrupt writers.
 * The underlying memory can also be written, so use a disposable region. */
void ts_fmaps_write_words(volatile void *destination, const void *source, uint16_t count);

#endif
