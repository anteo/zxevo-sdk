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

/* Physical RAM backing for one surface. page1 is zero when there is no
 * second page. The first page may be zero in modes that support it. */
typedef struct {
    uint16_t mode;
    zx_ram_page_t page0;
    zx_ram_page_t page1;
} zx_video_surface_t;

/* Select a surface for drawing. Map its pages into the supplied CPU window
 * addresses. Use NULL for each unused window. TSConf packed modes take
 * NULL for both windows and borrow W3 during drawing. The caller preserves
 * explicit mappings and keeps live code and data outside windows it remaps.
 * Display configuration is preserved. */
zx_status_t zx_draw_surface(const zx_video_surface_t *surface, zx_window_t window0,
                            zx_window_t window1);

/* Set the mode and show the surface. BaseConf requires a hardware screen's
 * exact pages. TSConf accepts an aligned physical page for the mode. CPU
 * mappings and the draw target are preserved. Serialize video operations
 * with paging and use blanking to hide intermediate register states. */
zx_status_t zx_display_surface(const zx_video_surface_t *surface);

/* Show a physical page in the current mode without changing the draw target
 * or CPU mappings. BaseConf accepts the first page of either hardware screen.
 * TSConf requires the appropriate page alignment for the current layout. */
zx_status_t zx_display_page(zx_ram_page_t page);

typedef struct {
    uint16_t width;
    uint16_t height;
} zx_video_size_t;

#endif
