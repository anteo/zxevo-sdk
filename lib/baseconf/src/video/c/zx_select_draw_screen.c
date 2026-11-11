#include <baseconf.h>
#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t zx_select_draw_screen(zx_screen_t screen) {
    bc_video_mode_t mode;
    bc_surface_t surface;
    bc_map_t map;
    zx_window_t windows[2];
    zx_status_t status;

    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease) return ZX_BUSY;
    if (screen > ZX_SCREEN_1) return ZX_INVALID_ARGUMENT;
    mode = bc_get_video_mode();
    if (mode == BC_VIDEO_UNKNOWN) return ZX_UNAVAILABLE;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled(mode)) return ZX_UNSUPPORTED;
#endif
    surface = bc_screen_surface(mode, screen);
    map = (bc_map_t)BC_PAGING_ACTIVE_MAP(bc_readback_register(0x0a));
    if ((uint8_t)map != bc_mem_active_map) return ZX_UNSAFE_CONTEXT;
    status = bc__video_find_page_windows(map, &surface, BC_VIDEO_STOP_ON_WINDOW_ERROR, windows);
    if (status != ZX_OK) return status;
    return bc_select_draw_surface(&surface);
}
