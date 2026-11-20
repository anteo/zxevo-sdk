#ifndef BASECONF_VIDEO_H
#define BASECONF_VIDEO_H

#include <stdint.h>
#include <zx/memory.h>
#include <zx/video.h>

typedef enum {
    BC_VIDEO_ZX_256 = ZX_VIDEO_ZX_256,
    BC_VIDEO_ZX_MULTICOLOR,
    BC_VIDEO_PENTAGON_256,
    BC_VIDEO_ATM_320,
    BC_VIDEO_ATM_640,
    BC_VIDEO_ATM_TEXT_80,
    BC_VIDEO_EVO_TEXT_80,
    BC_VIDEO_UNKNOWN = ZX_VIDEO_UNKNOWN
} bc_video_mode_t;

/* zx_get_video_mode decodes live FPGA registers. zx_set_video_mode requires
 * zx_init and returns ZX_UNSAFE_CONTEXT if the register update fails.
 * Mode changes preserve the displayed screen number and the draw target. */

/* Read the current beam color through 0DBD; it is raster-phase dependent. */
zx_status_t bc_read_beam_color(uint8_t *color);
/* Read the glyph-row byte currently exposed by port 0EBDh, not a row selected by
 * character code. The result depends on raster phase. NULL returns ZX_INVALID_ARGUMENT. */
zx_status_t bc_read_font_row(uint8_t *row);
/* Describe a standard hardware screen without changing paging or video state.
 * Supply a mode included in the library build and ZX_SCREEN_0 or ZX_SCREEN_1;
 * arguments are not validated. Single-page modes return page1 == 0. */
zx_video_surface_t bc_screen_surface(bc_video_mode_t mode, zx_screen_t screen);

#endif
