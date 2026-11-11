#ifndef ZX_FONT_H
#define ZX_FONT_H

#include <stdint.h>

typedef struct zx_font zx_font_t;
typedef enum { ZX_TEXT_OPAQUE, ZX_TEXT_TRANSPARENT } zx_text_bg_t;

/* Render at pixel coordinates x/y using the selected surface. The platform
 * defines the color bytes passed by its console. Transparent rendering
 * preserves background pixels and existing bitmap attributes. The callback
 * leaves the console state and selected surface intact. */
typedef void (*zx_font_draw_fn)(uint16_t x, uint16_t y, const zx_font_t *font, uint8_t code,
                                uint8_t ink, uint8_t paper, zx_text_bg_t background);

/* Narrow 5x8 font with a blank top scanline, for ASCII codes 32..127. */
extern const uint8_t zx_font5_data[96][8];

/* Built-in bitmap fonts. The 8x8 font advances eight pixels, and
 * the narrow 5x7 font uses a 5x8 cell and advances six pixels. */
extern const zx_font_t zx_font8;
extern const zx_font_t zx_font5;

/* Built-in glyph tables cover ASCII 32..127 with eight bytes per glyph, top
 * row first and leftmost pixel in bit 7. Width and height are 1..8, and
 * advance is at least width. Console rows advance by eight pixels.
 * The renderer interprets the glyph data. Set flags to zero for custom fonts. */
struct zx_font {
    const uint8_t *glyphs;
    uint8_t width;
    uint8_t height;
    uint8_t advance;
    uint8_t flags;
    zx_font_draw_fn draw;
};

#endif
