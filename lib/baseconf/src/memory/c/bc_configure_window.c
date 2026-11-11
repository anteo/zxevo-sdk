#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"
#include "../../video/internal.h"

zx_status_t bc_configure_window(bc_map_t map, zx_window_t window,
                                const bc_window_config_t *configuration) {
    bc_window_config_t config;
    uint8_t old_map;
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (map > BC_MAP_1 || window > ZX_WINDOW_3 || !configuration) return ZX_INVALID_ARGUMENT;
    /* The caller's configuration may live in a window that this call remaps. */
    config = *configuration;
    if (config.kind > BC_FLASH || config.substitute_from_7ffd_or_dos > 1 ||
        config.write_protected > 1)
        return ZX_INVALID_ARGUMENT;
    if (config.kind == BC_FLASH && config.physical_page > 31) return ZX_INVALID_ARGUMENT;
    if (bc_mem_active_window_lease) return ZX_BUSY;
    if (bc_video_operation_depth) return ZX_BUSY;
    if (bc_mem_pinned_window_mask & (1u << window)) return ZX_BUSY;
    old_map = bc_get_active_map();
    if (old_map != (uint8_t)map) {
        if (!bc__mem_pinned_maps_match()) return ZX_UNSAFE_CONTEXT;
        uint8_t paging = bc_readback_register(0x0a);
        if ((bc_readback_register(0x0b) & 4u) && (paging & 0x20u)) return ZX_BUSY;
        z80_outp(0x7ffd, (uint8_t)((paging & 0xefu) | ((uint8_t)map << 4)));
    }
    bc__mem_apply_window((uint8_t)window, &config);
    bc__video_invalidate_cache();
    if (old_map != (uint8_t)map) {
        uint8_t paging = bc_readback_register(0x0a);
        z80_outp(0x7ffd, (uint8_t)((paging & 0xefu) | (old_map << 4)));
    }
    return ZX_OK;
}
