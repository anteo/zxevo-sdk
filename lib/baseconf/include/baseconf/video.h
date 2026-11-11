#ifndef BASECONF_VIDEO_H
#define BASECONF_VIDEO_H

#include <stdint.h>
#include <baseconf.h>
#include <zx/color.h>

/* Decode the live FPGA mode registers; undocumented combinations return BC_VIDEO_UNKNOWN. */
bc_video_mode_t bc_get_video_mode(void);
/* Read the current beam color through 0DBD; it is raster-phase dependent. */
zx_status_t bc_read_beam_color(uint8_t *color);
/* Read the glyph-row byte currently exposed by port 0EBDh, not a row selected by
 * character code. The result depends on raster phase. NULL returns ZX_INVALID_ARGUMENT. */
zx_status_t bc_read_font_row(uint8_t *row);
/* Describe a standard hardware screen without changing paging or video state.
 * Supply a mode included in the library build and ZX_SCREEN_0 or ZX_SCREEN_1;
 * arguments are not validated. Single-page modes return page0 == page1. */
bc_surface_t bc_screen_surface(bc_video_mode_t mode, zx_screen_t screen);
/* Copy a software draw-surface descriptor and use its mode for drawing/geometry.
 * The surface can use a different format from the live FPGA video mode.
 * This call changes only the draw target. Prepare writable surface pages before
 * rendering. Page accessibility is checked when drawing begins. ZX_256,
 * ZX_MULTICOLOR and EVO_TEXT_80 require equal pages; other modes require two
 * different pages.
 * Returns ZX_INVALID_ARGUMENT for NULL/invalid descriptors, ZX_UNSUPPORTED for
 * excluded modes, and ZX_BUSY during a video operation. */
zx_status_t bc_select_draw_surface(const bc_surface_t *surface);
/* Set the hardware video mode and prepare the currently displayed screen for drawing.
 * Requires zx_init and an enabled page manager. Reuses writable page mappings and
 * replaces mappings in unpinned W1..W3 as needed, preferring W3. Pin every window
 * whose current mapping must be retained. Keeps the screen number and contents.
 * Returns ZX_UNAVAILABLE if the page manager is off or too few windows are available,
 * ZX_BUSY during a video or window lease, and ZX_UNSAFE_CONTEXT on readback mismatch.
 * Unknown modes return ZX_INVALID_ARGUMENT; excluded modes return ZX_UNSUPPORTED. */
zx_status_t bc_set_video_mode(bc_video_mode_t mode);
#endif
