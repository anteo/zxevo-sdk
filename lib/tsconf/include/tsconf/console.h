#ifndef TSCONF_CONSOLE_H
#define TSCONF_CONSOLE_H

#include <stdint.h>
#include <zx/console.h>

/* Console output uses the selected draw surface (see tsconf/video.h).
 * ZX uses a 256x192 bitmap. In 16c/256c the console occupies the selected
 * raster at canvas origin, independently of the hardware scroll offsets.
 * Bitmap columns are pixel width divided by font advance, capped at 255.
 * Native text uses the font in page surface.page ^ 1 and a grid of 64x24, 80x25,
 * 80x30 or 90x36 cells according to the raster. A library built with
 * TSCONF_VIDEO_60HZ=1 uses 30 instead of 36 rows. Keep ZX/native text
 * mapped. Packed drawing borrows and restores W3 outside an explicit
 * graphics group. Keep code, data, stack and active IRQ handlers outside
 * W3 and serialize use of the mapping.
 * Selecting a draw surface updates the grid immediately and resets the
 * cursor to (0,0) if its position is outside the new grid.
 * The console uses shared zx/color.h colors. */

/* Load codes 32..127 of the standard 8x8 ASCII font in a mapped writable
 * text-font page. Pass its aligned CPU window base, distinct from source. */
void ts_console_load_text_font(volatile void *font_page) __z88dk_fastcall;

/* Set the shared colors from a native attribute byte for the selected
 * surface. ZX uses FLASH/BRIGHT/PAPER/INK. Other modes take paper in bits
 * 7:4 and ink in bits 3:0. The ZX FLASH bit remains in effect when using
 * zx_set_ink and zx_set_paper. */
void ts_console_set_attribute(uint8_t attribute) __z88dk_fastcall;

/* Enable or disable automatic scroll on newline or wrap at the bottom.
 * Disabled initially. Scroll moves the console raster at canvas origin
 * up one cell row and clears its bottom row with the current paper.
 * Packed modes need up to 360 bytes of additional stack. */
void ts_console_set_autoscroll(uint8_t enabled) __z88dk_fastcall;

#endif
