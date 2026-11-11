#ifndef BASECONF_TEXT_H
#define BASECONF_TEXT_H

#include <baseconf.h>

/* The text operations use the current console colors and text background and require no z88dk
 * stdio or console shadow buffer.
 * Functions return ZX_OK on success; rendering requires zx_init and writable
 * surface pages already mapped, and propagates video-operation errors. */

/* Draw a NUL-terminated string with a raw table of 96 glyphs (ASCII 32..127),
   eight bytes per glyph. Always use an 8x8 cell and eight-pixel advance,
   independently of the selected console font; the selected font is unchanged.
   Stop at the right edge without wrapping or moving the cursor. Replace
   non-NUL bytes outside ASCII 32..127 with '?'.
   Return ZX_INVALID_ARGUMENT for NULL text/font or an out-of-grid starting
   cell. Return ZX_UNSUPPORTED in hardware text modes or if the selected
   bitmap text backend is excluded from this build. */
zx_status_t bc_text_draw_font(uint8_t column, uint8_t row, const char *text, const uint8_t *font);

#endif
