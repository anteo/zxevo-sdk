#ifndef ZX_GRAPHICS_H
#define ZX_GRAPHICS_H

#include <zx/video.h>
#include <zx/blit.h>

/* Values shared by the C API and the Z80 drawing backends. */
typedef enum { ZX_DRAW_SET = 0, ZX_DRAW_CLEAR = 1, ZX_DRAW_XOR = 2 } zx_draw_op_t;

/* Report the selected draw surface's pixel bounds, independent of the
 * visible raster. Return ZX_INVALID_ARGUMENT for NULL, ZX_NOT_INITIALIZED
 * if drawing has no target yet, or ZX_UNSUPPORTED for hardware text.
 * Use zx_console_get_size for cell dimensions. Leave *size untouched on error. */
zx_status_t zx_graphics_get_size(zx_video_size_t *size) __z88dk_fastcall;

/* Read a stored pixel index from the selected bitmap. In ZX mode return
 * the ink or paper index with BRIGHT, independent of the FLASH phase.
 * Packed formats return the stored pixel bits. Keep the surface accessible
 * and leave *index untouched on error. */
zx_status_t zx_read_pixel_index(uint16_t x, uint16_t y, uint8_t *index);

/* Hold the selected graphics surface across several drawing operations.
 * Pair each successful begin with an end. Surface changes are blocked
 * while the group is active. */
zx_status_t zx_graphics_begin(void);
zx_status_t zx_graphics_end(void);

/* Primitives use zero-based pixel coordinates on the selected draw surface
 * and clip to its bounds. Use a graphics group to retain any required
 * mapping across several operations.
 * Unavailable modes, inaccessible surfaces and unknown operations draw nothing.
 * In ZX and ATM_640 bitmaps, SET/CLEAR/XOR set/clear/toggle bitmap bits
 * without changing attributes. In packed modes, SET writes current ink, CLEAR
 * writes current paper, and XOR combines the stored index with current ink.
 * XOR applies to each point emitted by a shape. A point visited twice keeps
 * its original value. Supported modes depend on the library build.
 * On TSConf packed surfaces, keep code, data, stack and active IRQ handlers
 * outside W3. Keep ZX bitmaps mapped while drawing. */

/* Draw a single pixel. */
void zx_draw_plot_op(int16_t x, int16_t y, zx_draw_op_t operation);
/* Draw a one-pixel circle outline centered at (x,y). Negative radius draws
 * nothing. TSConf supports radii up to 511. */
void zx_draw_circle_op(int16_t x, int16_t y, int16_t radius, zx_draw_op_t operation);
/* Draw an axis-aligned ellipse outline centered at (cx,cy), with semi-axes rx/ry.
 * Negative semi-axes draw nothing. A zero semi-axis produces a line segment.
 * TSConf supports semi-axes up to 511. */
void zx_draw_ellipse_op(int16_t cx, int16_t cy, int16_t rx, int16_t ry, zx_draw_op_t operation);
/* Draw an inclusive horizontal segment at y; endpoints may be in either order. */
void zx_draw_hline_op(int16_t x0, int16_t x1, int16_t y, zx_draw_op_t operation);
/* Draw a segment including both endpoints. */
void zx_draw_line_op(int16_t x0, int16_t y0, int16_t x1, int16_t y1, zx_draw_op_t operation);
/* Draw an inclusive vertical segment at x; endpoints may be in either order. */
void zx_draw_vline_op(int16_t x, int16_t y0, int16_t y1, zx_draw_op_t operation);

/* Shorthands for the corresponding _op functions with ZX_DRAW_SET. */
void zx_draw_plot(int16_t x, int16_t y);
void zx_draw_circle(int16_t x, int16_t y, int16_t radius);
void zx_draw_ellipse(int16_t cx, int16_t cy, int16_t rx, int16_t ry);
void zx_draw_hline(int16_t x0, int16_t x1, int16_t y);
void zx_draw_line(int16_t x0, int16_t y0, int16_t x1, int16_t y1);
void zx_draw_vline(int16_t x, int16_t y0, int16_t y1);

/* Shorthands for the corresponding _op functions with ZX_DRAW_XOR. */
void zx_draw_plot_xor(int16_t x, int16_t y);
void zx_draw_circle_xor(int16_t x, int16_t y, int16_t radius);
void zx_draw_ellipse_xor(int16_t cx, int16_t cy, int16_t rx, int16_t ry);
void zx_draw_hline_xor(int16_t x0, int16_t x1, int16_t y);
void zx_draw_line_xor(int16_t x0, int16_t y0, int16_t x1, int16_t y1);
void zx_draw_vline_xor(int16_t x, int16_t y0, int16_t y1);

/* Shorthands for the corresponding _op functions with ZX_DRAW_CLEAR. */
void zx_draw_plot_clear(int16_t x, int16_t y);
void zx_draw_circle_clear(int16_t x, int16_t y, int16_t radius);
void zx_draw_ellipse_clear(int16_t cx, int16_t cy, int16_t rx, int16_t ry);
void zx_draw_hline_clear(int16_t x0, int16_t x1, int16_t y);
void zx_draw_line_clear(int16_t x0, int16_t y0, int16_t x1, int16_t y1);
void zx_draw_vline_clear(int16_t x, int16_t y0, int16_t y1);

/* Fill or clear a clipped rectangle by scanline. A nonpositive width or
 * height draws nothing. Fill uses SET and clear uses CLEAR. */
void zx_draw_fill_rect(int16_t x, int16_t y, int16_t width, int16_t height);
void zx_draw_clear_rect(int16_t x, int16_t y, int16_t width, int16_t height);

#endif
