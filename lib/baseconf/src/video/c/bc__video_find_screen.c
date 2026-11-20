#include "internal.h"

zx_status_t bc__video_find_screen(uint16_t mode, zx_ram_page_t page, zx_screen_t *screen) {
    zx_video_surface_t front;

    if (mode > BC_VIDEO_EVO_TEXT_80) return ZX_INVALID_ARGUMENT;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled((bc_video_mode_t)mode)) return ZX_UNSUPPORTED;
#endif
    front = bc_screen_surface((bc_video_mode_t)mode, ZX_SCREEN_0);
    if (page == front.page0) {
        *screen = ZX_SCREEN_0;
        return ZX_OK;
    }
    /* In every BaseConf layout screen 1 adds two to each physical page. */
    if (page == front.page0 + 2u) {
        *screen = ZX_SCREEN_1;
        return ZX_OK;
    }
    return ZX_INVALID_ARGUMENT;
}
