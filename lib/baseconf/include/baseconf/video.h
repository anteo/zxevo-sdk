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

/* Prepared slots cache the screen bit and addressing mode for zx_display_buffer.
 * zx_set_video_mode refreshes these for existing slots. zx_display_buffer reads
 * the current 7FFD byte and changes only its screen bit. After changing the video
 * or paging configuration (including BF.0) outside the SDK, call bc_resync
 * and prepare the slots again. A temporary lease preserves prepared slots.
 * Drawing and selection resume after release. Slots can share CPU windows.
 * Preparation checks the stack and pinned windows before allowing a bank
 * change. Keep the stack (including interrupt handlers' stack use) outside
 * every window that the slots remap for as long as you use them.
 * Once their common format and windows are active, switching slots updates
 * the banks that differ between them and their cached page numbers.
 * A permanent remap invalidates slots using that window in the active map.
 * zx_display_page reads the live mode and paging registers. */

/* Read the current beam color through readback register 0Dh; it is raster-phase dependent. */
zx_status_t bc_read_beam_color(uint8_t *color);
/* Read the glyph-row byte currently exposed by readback register 0Eh.
 * The result depends on raster phase. NULL returns ZX_INVALID_ARGUMENT. */
zx_status_t bc_read_font_row(uint8_t *row);
#endif
