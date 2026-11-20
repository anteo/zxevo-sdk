#include "internal.h"
#include "../../memory/internal.h"

zx_status_t zx_draw_surface(const zx_video_surface_t *surface, zx_window_t window0,
                                   zx_window_t window1) {
    bc__draw_surface_t target;
    bc_window_config_t config = {BC_RAM, 0, 0, 0};
    uint8_t single_page, protected_windows, replace0, replace1 = 0;
    zx_status_t status;

    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease || bc_video_operation_depth) return ZX_BUSY;
    if (!surface || surface->mode > BC_VIDEO_EVO_TEXT_80) return ZX_INVALID_ARGUMENT;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled(surface->mode)) return ZX_UNSUPPORTED;
#endif
    single_page = (surface->mode == BC_VIDEO_ZX_256 || surface->mode == BC_VIDEO_ZX_MULTICOLOR ||
                   surface->mode == BC_VIDEO_EVO_TEXT_80);
    if (single_page != !surface->page1 || single_page != !window1 ||
        (!single_page && (window0 == window1 || surface->page0 == surface->page1)))
        return ZX_INVALID_ARGUMENT;
    if (BC_PAGING_ACTIVE_MAP(bc_readback_register(0x0a)) != bc_mem_active_map)
        return ZX_UNSAFE_CONTEXT;
    if (!(bc_readback_register(0x0c) & 0x20u)) return ZX_UNAVAILABLE;
    /* Copy the descriptor before changing any of the caller's mappings. */
    target.mode = (bc_video_mode_t)surface->mode;
    target.page0 = surface->page0;
    target.page1 = single_page ? target.page0 : surface->page1;
    status = bc__video_check_page_window((bc_map_t)bc_mem_active_map, window0, target.page0);
    if (status != ZX_OK && status != ZX_UNAVAILABLE) return status;
    replace0 = status == ZX_UNAVAILABLE;
    if (!single_page) {
        status = bc__video_check_page_window((bc_map_t)bc_mem_active_map, window1, target.page1);
        if (status != ZX_OK && status != ZX_UNAVAILABLE) return status;
        replace1 = status == ZX_UNAVAILABLE;
    }

    protected_windows = bc_mem_pinned_window_mask | (1u << (zx__mem_read_sp() >> 14));
    if ((replace0 && (protected_windows & ZX_WINDOW_MASK(window0))) ||
        (replace1 && (protected_windows & ZX_WINDOW_MASK(window1))))
        return ZX_BUSY;

    if (replace0) {
        config.physical_page = target.page0;
        bc__mem_apply_window(ZX__WINDOW_INDEX(window0), &config);
    }
    if (replace1) {
        config.physical_page = target.page1;
        bc__mem_apply_window(ZX__WINDOW_INDEX(window1), &config);
    }
    bc_video_draw_windows[0] = window0;
    bc_video_draw_windows[1] = single_page ? window0 : window1;
    bc__video_commit_surface(&target);
    return ZX_OK;
}
