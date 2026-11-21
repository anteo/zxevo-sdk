#ifndef ZX_VIDEO_H
#define ZX_VIDEO_H

#include <stddef.h>
#include <stdint.h>
#include <zx/memory.h>
#include <zx/status.h>

#define ZX_VIDEO_ZX_256 0u
#define ZX_VIDEO_UNKNOWN 0xffu

/* Set the display mode. CPU page mappings and the draw surface are preserved.
 * ZX_VIDEO_ZX_256 selects the standard 256x192 ZX bitmap. Other numbers are
 * platform-specific.
 * Foreign or invalid numbers return ZX_INVALID_ARGUMENT. Modes excluded from
 * the library build return ZX_UNSUPPORTED. See the platform video header for
 * paging, draw target and initialization requirements. */
zx_status_t zx_set_video_mode(uint16_t mode);

/* Get the current display mode or ZX_VIDEO_UNKNOWN if it cannot be determined. */
uint16_t zx_get_video_mode(void);

typedef enum { ZX_SCREEN_0, ZX_SCREEN_1 } zx_screen_t;

/* Select the drawing format and physical RAM backing. Map page into window
 * for CPU access. TSConf packed modes take NULL for window and borrow W3
 * during drawing. The caller preserves explicit mappings and keeps live code
 * and data outside windows it remaps. Display configuration is preserved. */
zx_status_t zx_set_draw_buffer(uint16_t mode, zx_ram_page_t page, zx_window_t window);

/* Select one draw buffer backed by two explicit page/window pairs. BaseConf
 * requires a two-page format and distinct pages and writable windows.
 * TSConf returns ZX_UNSUPPORTED. The same paging rules apply as above. */
zx_status_t zx_set_split_draw_buffer(uint16_t mode, zx_ram_page_t page0, zx_window_t window0,
                                    zx_ram_page_t page1, zx_window_t window1);

#define ZX_DRAW_BUFFER_SLOTS 2u

/* Prepare slot 0 or 1 using the same format and mapping rules as the setters.
 * This can change CPU mappings. It does not select the slot or change the
 * display. Keep both slots' explicit mappings resident to switch between them.
 * TSConf returns ZX_UNSUPPORTED for a split buffer. */
zx_status_t zx_prepare_draw_buffer(uint8_t slot, uint16_t mode, zx_ram_page_t page,
                                   zx_window_t window);
zx_status_t zx_prepare_split_draw_buffer(uint8_t slot, uint16_t mode, zx_ram_page_t page0,
                                         zx_window_t window0, zx_ram_page_t page1,
                                         zx_window_t window1);

/* Select a prepared slot without remapping pages. Return ZX_UNAVAILABLE if
 * it is empty or its paging context has been invalidated, ZX_INVALID_ARGUMENT
 * if out of range. */
zx_status_t zx_select_draw_buffer(uint8_t slot) __z88dk_fastcall;

/* Show a prepared slot's first physical page using zx_display_page rules.
 * Preserve the display mode, draw target and CPU mappings. An empty or
 * invalidated slot returns ZX_UNAVAILABLE. Return ZX_INVALID_ARGUMENT
 * if the slot number is out of range. */
zx_status_t zx_display_buffer(uint8_t slot) __z88dk_fastcall;

/* Show a physical page in the current mode without changing the draw target
 * or CPU mappings. BaseConf accepts the first page of either hardware screen.
 * TSConf requires the appropriate page alignment for the current layout. */
zx_status_t zx_display_page(zx_ram_page_t page);

typedef struct {
    uint16_t width;
    uint16_t height;
} zx_video_size_t;

#endif
