#include <baseconf.h>
#include "../internal.h"
#include "internal.h"

zx_status_t bc_select_draw_surface(const bc_surface_t *surface) {
    uint8_t single_page;
    if (bc_video_operation_depth) return ZX_BUSY;
    if (!surface || surface->mode > BC_VIDEO_EVO_TEXT_80) return ZX_INVALID_ARGUMENT;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled(surface->mode)) return ZX_UNSUPPORTED;
#endif
    single_page = (surface->mode == BC_VIDEO_ZX_256 || surface->mode == BC_VIDEO_ZX_MULTICOLOR ||
                   surface->mode == BC_VIDEO_EVO_TEXT_80);
    if ((single_page && surface->page0 != surface->page1) ||
        (!single_page && surface->page0 == surface->page1))
        return ZX_INVALID_ARGUMENT;
    bc__video_commit_surface(surface);
    return ZX_OK;
}
