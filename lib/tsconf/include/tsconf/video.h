#ifndef TSCONF_VIDEO_H
#define TSCONF_VIDEO_H

#include <stdint.h>
#include <zx/video.h>

#define TS_VIDEO_ZX 0x00u
#define TS_VIDEO_16C 0x01u
#define TS_VIDEO_256C 0x02u
#define TS_VIDEO_TEXT 0x03u
#define TS_VIDEO_HIDE_TSU 0x10u
#define TS_VIDEO_HIDE_GFX 0x20u
#define TS_VIDEO_256X192 0x00u
#define TS_VIDEO_320X200 0x40u
#define TS_VIDEO_320X240 0x80u
#define TS_VIDEO_360X288 0xc0u

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

/* Write VConfig and remember its layout for ts_video_select_draw_screen.
 * Combine the mode, raster size and layer flags. Leaves the draw target alone. */
void ts_video_set_config(uint8_t config) __z88dk_fastcall;

/* Select the display's physical base page. Align it to 8 pages for
 * 16-color mode or 16 pages for 256-color mode. Leaves the draw target alone. */
void ts_video_set_page(uint8_t page) __z88dk_fastcall;

/* Draw surface with a TS_VIDEO_* mode and raster, and its physical base page.
 * ZX and text need page mapped at a writable 16 KiB-aligned CPU address
 * (base). Packed drawing uses the physical page and borrows W3. For that
 * layout, base is unused and page must be aligned as for ts_video_set_page. */
typedef struct {
    uint8_t config;
    uint8_t page;
    volatile void *base;
} ts_surface_t;

/* Report the native TSConf raster area in pixels for the last VConfig set
 * by this library. Hardware text doubles the horizontal pixel count.
 * With TSCONF_VIDEO_60HZ=1 at library build time, 360x288 has 240 lines.
 * Return ZX_INVALID_ARGUMENT for NULL or ZX_NOT_INITIALIZED for an unknown
 * VConfig. Leave the output untouched on error. Blanking and scrolling do
 * not change the size. */
zx_status_t ts_video_get_raster_size(zx_video_size_t *size) __z88dk_fastcall;

/* Copy a draw surface for console and graphics output. This can have a
 * different layout or page from the display. Only the mode and raster bits
 * of config are used. Leaves video registers and CPU mappings alone.
 * Return ZX_INVALID_ARGUMENT for NULL or invalid alignment, ZX_UNSUPPORTED
 * for an excluded mode or ZX_BUSY while a graphics group is open. */
zx_status_t ts_video_select_draw_surface(const ts_surface_t *surface) __z88dk_fastcall;

/* Select a draw page using the layout last set by ts_video_set_config or
 * ts_video_set_mode. Same page/base requirements as ts_surface_t. Leaves
 * video registers and CPU mappings alone. Return ZX_NOT_INITIALIZED if
 * VConfig is unknown, or the draw-surface selection status. */
zx_status_t ts_video_select_draw_screen(uint8_t page, volatile void *base);

/* Set VConfig and VPage and select the same surface for drawing. The caller
 * prepares the CPU mapping and serializes mode changes, paging and drawing.
 * Return the draw-surface selection status. On error leave both the display
 * and the draw surface untouched. */
zx_status_t ts_video_set_mode(uint8_t config, uint8_t page, volatile void *base);

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

/* Map FMAPS at a 4 KiB-aligned CPU address. Use disposable backing memory
 * and keep code, data and stack clear of the aperture. */
void ts_fmaps_enable(uint16_t base) __z88dk_fastcall;
void ts_fmaps_disable(void);

/* Copy count little-endian words (0..256) to CRAM or SFILE in an already
 * enabled FMAPS aperture, with low byte first. Use an even destination and
 * stay within the selected region. Source and destination must not overlap.
 * Caller owns FMAPS and excludes DMA to internal files and interrupt writers.
 * The underlying memory can also be written, so use a disposable region. */
void ts_fmaps_write_words(volatile void *destination, const void *source, uint16_t count);

#endif
