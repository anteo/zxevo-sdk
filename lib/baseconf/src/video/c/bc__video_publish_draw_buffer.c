#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t bc__video_publish_draw_buffer(const bc__draw_buffer_t *buffer) __z88dk_fastcall {
    bc__draw_surface_t target = {(bc_video_mode_t)buffer->mode, buffer->page0, buffer->page1};
    bc_video_bound_slots = 0;
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
