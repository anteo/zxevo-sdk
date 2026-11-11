#include <baseconf.h>
#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t bc__video_sync_cache(void) {
    uint8_t fpga_config;
    uint8_t map = bc_mem_active_map;
    zx_window_t windows[2];
    zx_status_t status;

    bc_video_cache_valid = 0;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled(bc_video_draw_surface_state.mode)) return ZX_UNSUPPORTED;
#endif
    /* Rendering uses the selected format and the current CPU mappings. */
    if (BC_PAGING_ACTIVE_MAP(bc_readback_register(0x0a)) != map) return ZX_UNSAFE_CONTEXT;
    fpga_config = bc_readback_register(0x0c);

    status = bc__video_find_page_windows((bc_map_t)map, &bc_video_draw_surface_state,
                                         BC_VIDEO_SKIP_WINDOW_ERRORS, windows);
    bc_video_cached_map = map;
    bc_video_cached_manager_enabled = (uint8_t)((fpga_config & 0x20u) != 0u);
    bc_video_page0_base = (uint16_t)windows[0] << 14;
    bc_video_page1_base = (uint16_t)windows[1] << 14;
    bc_video_cached_width = bc__video_width();
    bc_video_cached_height = bc__video_height();
    bc_video_cache_valid = 1;
    return bc_video_cached_manager_enabled ? status : ZX_UNAVAILABLE;
}
