#ifndef ZX_CONSOLE_H
#define ZX_CONSOLE_H

#include <zx/color.h>
#include <zx/font.h>
#include <zx/status.h>

typedef struct {
    uint8_t columns;
    uint8_t rows;
} zx_console_size_t;

/* Clear the selected draw surface using the current paper/attribute and
 * reset the cursor on success. */
zx_status_t zx_console_clear(void);
/* Report the grid size in cells. Leave the output untouched on error. */
zx_status_t zx_console_get_size(zx_console_size_t *size) __z88dk_fastcall;
/* Move the cursor to a zero-based cell. Return ZX_INVALID_ARGUMENT for
 * coordinates outside the grid. */
zx_status_t zx_console_gotoxy(uint8_t column, uint8_t row);
/* Set the background for console text output. The initial mode is opaque.
 * Invalid values return ZX_INVALID_ARGUMENT. Hardware text output returns
 * ZX_UNSUPPORTED when transparent text is requested. Clears still use paper. */
zx_status_t zx_console_set_text_bg(zx_text_bg_t background) __z88dk_fastcall;
/* Write at the cursor. LF starts the next row, CR resets the column,
 * backspace moves left and TAB emits spaces. Other bytes below 32 are
 * ignored. Output wraps at the right edge and clamps at the bottom unless
 * platform-specific scrolling is enabled. */
zx_status_t zx_console_putc(char code);
/* Write a NUL-terminated string at the cursor with the same controls and
 * wrapping as zx_console_putc. Keep the string accessible during output.
 * Return the first error, ZX_INVALID_ARGUMENT for NULL or ZX_OK for an
 * empty string. No newline is appended. */
zx_status_t zx_console_puts(const char *text) __z88dk_fastcall;
/* Draw a printable run with the current text background without moving the
 * cursor. Stop before a byte below 32 or the right edge. Keep text accessible. */
zx_status_t zx_console_draw(uint8_t column, uint8_t row, const char *text);
/* Override the background for this run. Opaque rendering uses paper.
 * Transparent rendering preserves unmarked pixels and existing attributes in
 * bitmap modes. Hardware text rejects nonempty transparent runs. */
zx_status_t zx_console_draw_op(uint8_t column, uint8_t row, const char *text,
                               zx_text_bg_t background);
/* Borrow a valid bitmap font and reset the cursor. Native text modes use
 * their hardware fonts. Keep the descriptor and glyphs CPU-accessible. */
zx_status_t zx_console_set_font(const zx_font_t *font) __z88dk_fastcall;
/* Return the borrowed bitmap font, or NULL if none is selected. */
const zx_font_t *zx_console_get_font(void);

#endif
