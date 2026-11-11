#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"
#include "../../video/internal.h"

zx_status_t bc_set_page_manager_enabled(uint8_t enabled) {
    uint8_t bf;
    uint8_t config;

    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease) return ZX_BUSY;
    if (bc_video_operation_depth) return ZX_BUSY;
    /* Disabling the pager replaces every window with service ROM. */
    if (!enabled) return ZX_UNSAFE_CONTEXT;
    if (!bc_mem_maps_prepared) return ZX_UNAVAILABLE;
    if (!bc__mem_pinned_maps_match()) return ZX_UNSAFE_CONTEXT;
    bf = bc__mem_shadow_scope_begin();
    /* Readback bit 5 becomes A8 of the system port. */
    config = (uint8_t)(bc_readback_register(0x0c) | 0x20u);
    z80_outp(bc__mem_xx77_port(config), (uint8_t)(config & 0x0fu));
    bc__mem_shadow_scope_end(bf);
    bc__video_invalidate_cache();
    return ZX_OK;
}
