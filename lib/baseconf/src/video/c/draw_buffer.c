#include "../internal.h"
#include "../../memory/internal.h"

/* Only a remap of one of this buffer's windows makes its cached mapping stale. */
static void forget_window(zx_window_t window) {
    uint8_t high = (uint8_t)((uintptr_t)window >> 8);
    uint8_t index;
    for (index = 0; index < ZX_DRAW_BUFFER_SLOTS; ++index) {
        bc__draw_buffer_t *buffer = &bc_video_prepared_buffers[index];
        if (buffer->window0_high == high || buffer->window1_high == high) buffer->window0_high = 0;
    }
}

static zx_status_t prepare_draw_buffer(bc__draw_buffer_t *buffer, uint16_t mode,
                                       zx_ram_page_t page0, zx_window_t window0,
                                       zx_ram_page_t page1, zx_window_t window1) {
    uint8_t single_page, replace0, replace1 = 0;
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

    if (replace0 || replace1) {
        bc_window_config_t config = {BC_RAM, page0, 0, 0};
        uint8_t protected_windows = bc_mem_pinned_window_mask | (1u << (zx__mem_read_sp() >> 14));
        if ((replace0 && (protected_windows & ZX_WINDOW_MASK(window0))) ||
            (replace1 && (protected_windows & ZX_WINDOW_MASK(window1))))
            return ZX_BUSY;

        bc__video_invalidate_draw_cache();
        if (replace0) {
            forget_window(window0);
            bc__mem_apply_window(window0, &config);
        }
        if (replace1) {
            forget_window(window1);
            config.physical_page = page1;
            bc__mem_apply_window(window1, &config);
        }
    }
    buffer->window0_high = (uint8_t)((uintptr_t)window0 >> 8);
    buffer->window1_high = (uint8_t)((uintptr_t)(single_page ? window0 : window1) >> 8);
    buffer->mode = (uint8_t)mode;
    buffer->page0 = page0;
    buffer->page1 = single_page ? page0 : page1;
    return ZX_OK;
}

zx_status_t bc__video_publish_draw_buffer(const bc__draw_buffer_t *buffer) __z88dk_fastcall {
    bc__draw_surface_t target = {(bc_video_mode_t)buffer->mode, buffer->page0, buffer->page1};
    bc_video_cache_valid = 0;
    bc_video_page0_base = (uint16_t)buffer->window0_high << 8;
    bc_video_page1_base = (uint16_t)buffer->window1_high << 8;
    bc__video_commit_surface(&target);
    bc_video_cached_width = bc__video_width();
    bc_video_cached_height = bc__video_height();
    bc_video_cached_map = bc_mem_active_map;
    bc_video_cached_manager_enabled = 1;
    bc_video_cache_valid = 1;
    return ZX_OK;
}

zx_status_t zx_prepare_draw_buffer(uint8_t slot, uint16_t mode, zx_ram_page_t page,
                                   zx_window_t window) {
    zx_status_t status;
    if (slot >= ZX_DRAW_BUFFER_SLOTS) return ZX_INVALID_ARGUMENT;
    status = prepare_draw_buffer(&bc_video_prepared_buffers[slot], mode, page, window, 0, NULL);
    if (status == ZX_OK) bc__video_refresh_display_buffers();
    return status;
}

zx_status_t zx_prepare_split_draw_buffer(uint8_t slot, uint16_t mode, zx_ram_page_t page0,
                                         zx_window_t window0, zx_ram_page_t page1,
                                         zx_window_t window1) {
    zx_status_t status;
    if (slot >= ZX_DRAW_BUFFER_SLOTS || !window1) return ZX_INVALID_ARGUMENT;
    status = prepare_draw_buffer(&bc_video_prepared_buffers[slot], mode, page0, window0,
                                 page1, window1);
    if (status == ZX_OK) bc__video_refresh_display_buffers();
    return status;
}

zx_status_t zx_set_draw_buffer(uint16_t mode, zx_ram_page_t page, zx_window_t window) {
    bc__draw_buffer_t buffer;
    zx_status_t status = prepare_draw_buffer(&buffer, mode, page, window, 0, NULL);
    return status == ZX_OK ? bc__video_publish_draw_buffer(&buffer) : status;
}

zx_status_t zx_set_split_draw_buffer(uint16_t mode, zx_ram_page_t page0, zx_window_t window0,
                                    zx_ram_page_t page1, zx_window_t window1) {
    bc__draw_buffer_t buffer;
    zx_status_t status;
    if (!window1) return ZX_INVALID_ARGUMENT;
    status = prepare_draw_buffer(&buffer, mode, page0, window0, page1, window1);
    return status == ZX_OK ? bc__video_publish_draw_buffer(&buffer) : status;
}
