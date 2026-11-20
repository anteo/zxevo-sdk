#ifndef ZX_VIDEO_H
#define ZX_VIDEO_H

#include <stdint.h>
#include <zx/status.h>

#define ZX_VIDEO_ZX_256 0u
#define ZX_VIDEO_UNKNOWN 0xffu

/* Set a display mode supported by the active platform. ZX_VIDEO_ZX_256
 * selects the standard 256x192 ZX bitmap. Other numbers are platform-specific.
 * Foreign or invalid numbers return ZX_INVALID_ARGUMENT. Modes excluded from
 * the library build return ZX_UNSUPPORTED. See the platform video header for
 * paging, draw target and initialization requirements. */
zx_status_t zx_set_video_mode(uint16_t mode);

/* Get the current display mode or ZX_VIDEO_UNKNOWN if it cannot be determined. */
uint16_t zx_get_video_mode(void);

typedef enum { ZX_SCREEN_0, ZX_SCREEN_1 } zx_screen_t;

typedef struct {
    uint16_t width;
    uint16_t height;
} zx_video_size_t;

/* Select a standard draw screen without changing the displayed screen or
 * mapping pages. For portable ZX bitmap output use screen 0 (page 5) or
 * screen 1 (page 7) with the display already configured and the screen page
 * mapped to writable RAM. On TSConf screen 0 uses W1 at 4000h, which the
 * caller maps to page 5. Screen 1 needs page 7 in W2 or W3. BaseConf also
 * supports its other live video layouts through this function. */
zx_status_t zx_select_draw_screen(zx_screen_t screen);

/* Display a standard screen without changing CPU mappings or the draw target.
 * For portable ZX output, configure ZX mode first, then pass ZX_SCREEN_0
 * (page 5) or ZX_SCREEN_1 (page 7). BaseConf also supports its other enabled
 * layouts. TSConf applies the change at a scanline boundary, returns
 * ZX_NOT_INITIALIZED until the SDK sets the display mode, and ZX_UNSUPPORTED
 * for non-ZX display modes or builds without ZX. An invalid screen returns
 * ZX_INVALID_ARGUMENT. An active graphics group can return ZX_BUSY. */
zx_status_t zx_show_screen(zx_screen_t screen);

#endif
