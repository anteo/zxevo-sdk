#include "../internal.h"
#include "../../memory/internal.h"

/* All windows are checked before any register is written. When preparing a slot,
 * keep an active draw window accessible until the new slot is selected. */
static void configure_page(zx_window_t window, zx_ram_page_t page, uint8_t deferred) {
    bc_window_config_t config = {BC_RAM, page, 0, 0};
    if (deferred && bc_video_surface_selected &&
        ((uintptr_t)window == bc_video_page0_base || (uintptr_t)window == bc_video_page1_base)) {
        const bc_window_config_t *current =
            &bc_mem_window_cache[bc_mem_active_map][ZX__WINDOW_INDEX(window)];
        if (current->kind == BC_RAM && !current->substitute_from_7ffd_or_dos &&
            !current->write_protected)
            return;
    }
    if (deferred) bc__video_invalidate_draw_cache();
    else bc__video_invalidate_window(window);
    bc__mem_apply_window(window, &config);
}

/* A matching current page can still be replaced later by the other slot.
 * Validate that window at prepare time, before changing either mapping. */
static uint8_t changes_bank(const bc__draw_buffer_t *other, zx_window_t window, zx_ram_page_t page) {
    uint8_t high = (uint8_t)((uintptr_t)window >> 8);
    return other && other->window0_high &&
           ((other->window0_high == high && other->page0 != page) ||
            (other->window1_high == high && other->page1 != page));
}

zx_status_t bc__video_prepare_draw_buffer(bc__draw_buffer_t *buffer, uint16_t mode,
                                         zx_ram_page_t page0, zx_window_t window0,
                                         zx_ram_page_t page1, zx_window_t window1,
                                         const bc__draw_buffer_t *other) {
    uint8_t single_page, replace0, replace1 = 0;
    uint8_t change0, change1;
    bc_map_t map;
    zx_status_t status;

    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease || bc_video_operation_depth) return ZX_BUSY;
    if (mode > BC_VIDEO_EVO_TEXT_80) return ZX_INVALID_ARGUMENT;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled((bc_video_mode_t)mode)) return ZX_UNSUPPORTED;
#endif
    single_page = mode == BC_VIDEO_ZX_256 || mode == BC_VIDEO_ZX_MULTICOLOR ||
                  mode == BC_VIDEO_EVO_TEXT_80;
    if (single_page != !window1 || (!single_page && (window0 == window1 || page0 == page1)))
        return ZX_INVALID_ARGUMENT;
    map = (bc_map_t)bc_mem_active_map;
    if (BC_PAGING_ACTIVE_MAP(bc_readback_register(0x0a)) != map) return ZX_UNSAFE_CONTEXT;
    if (!(bc_readback_register(0x0c) & 0x20u)) return ZX_UNAVAILABLE;
    status = bc__video_check_page_window(map, window0, page0);
    if (status != ZX_OK && status != ZX_UNAVAILABLE) return status;
    replace0 = status == ZX_UNAVAILABLE;
    if (!single_page) {
        status = bc__video_check_page_window(map, window1, page1);
        if (status != ZX_OK && status != ZX_UNAVAILABLE) return status;
        replace1 = status == ZX_UNAVAILABLE;
    }

    change0 = replace0 || changes_bank(other, window0, page0);
    change1 = replace1 || (!single_page && changes_bank(other, window1, page1));
    if (change0 || change1) {
        uint8_t protected_windows = bc_mem_pinned_window_mask | (1u << (zx__mem_read_sp() >> 14));
        if ((change0 && (protected_windows & ZX_WINDOW_MASK(window0))) ||
            (change1 && (protected_windows & ZX_WINDOW_MASK(window1))))
            return ZX_BUSY;
        if (replace0) configure_page(window0, page0, other != NULL);
        if (replace1) configure_page(window1, page1, other != NULL);
    }
    buffer->window0_high = (uint8_t)((uintptr_t)window0 >> 8);
    buffer->window1_high = (uint8_t)((uintptr_t)(single_page ? window0 : window1) >> 8);
    buffer->mode = (uint8_t)mode;
    buffer->page0 = page0;
    buffer->page1 = single_page ? page0 : page1;
    if (other) bc_video_bound_slots = 0;
    return ZX_OK;
}
