#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"
#include "../../video/internal.h"

zx_status_t bc_select_map(bc_map_t map) {
    uint8_t state;
    if (map > BC_MAP_1) return ZX_INVALID_ARGUMENT;
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease) return ZX_BUSY;
    if (bc_video_operation_depth) return ZX_BUSY;
    state = bc_readback_register(0x0a);
    if (((state >> 4) & 1u) != (uint8_t)map && !bc__mem_pinned_maps_match())
        return ZX_UNSAFE_CONTEXT;
    if (((state >> 4) & 1u) != (uint8_t)map && (bc_readback_register(0x0b) & 4u) && (state & 0x20u))
        return ZX_BUSY;
    z80_outp(0x7ffd, (uint8_t)((state & 0xefu) | ((uint8_t)map << 4)));
    bc_mem_active_map = (uint8_t)map;
    bc__video_invalidate_cache();
    return ZX_OK;
}
