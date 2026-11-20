#include "internal.h"

/* The low nibble selects the first page, the high nibble the second.
 * A repeated page identifies a single-page layout. */
static const uint8_t screen0_pages[] = {0x55, 0x55, 0x54, 0x51, 0x51, 0x51, 0x88};

zx_video_surface_t bc_screen_surface(bc_video_mode_t mode, zx_screen_t screen) {
    zx_video_surface_t surface = {mode, 5, 7};
    uint8_t pages;

    if (mode > BC_VIDEO_EVO_TEXT_80) return surface;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled(mode)) return surface;
#endif

    pages = screen0_pages[mode];
    if (screen) pages += 0x22u;
    surface.page0 = pages & 0x0fu;
    surface.page1 = pages >> 4;
    if (surface.page1 == surface.page0) surface.page1 = 0;
    return surface;
}
