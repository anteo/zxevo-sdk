#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t zx_display_surface(const zx_video_surface_t *surface) {
    zx_screen_t screen, previous;
    zx_video_surface_t target;
    zx_status_t status;

    if (!surface) return ZX_INVALID_ARGUMENT;
    status = bc__video_find_screen(surface->mode, surface->page0, &screen);
    if (status != ZX_OK) return status;
    target = bc_screen_surface((bc_video_mode_t)surface->mode, screen);
    if (surface->page1 != target.page1) return ZX_INVALID_ARGUMENT;
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease || bc_video_operation_depth) return ZX_BUSY;

    previous = BC_PAGING_SCREEN(bc_readback_register(0x0a));
    status = bc_select_screen(screen);
    if (status != ZX_OK) return status;
    status = zx_set_video_mode(surface->mode);
    if (status != ZX_OK && previous != screen) {
        zx_status_t restore = bc_select_screen(previous);
        if (restore != ZX_OK) return restore;
    }
    return status;
}
