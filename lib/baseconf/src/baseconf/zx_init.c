#include <baseconf.h>
#include "../internal.h"
#include "../memory/internal.h"
#include "../video/internal.h"

static uint8_t bc__mem_mask_for_address(uint16_t address) {
    static const uint8_t masks[4] = {1u, 2u, 4u, 8u};
    return masks[address >> 14];
}

static uint8_t bc__mem_calculate_pinned_windows(void) {
    uint8_t mask = bc__mem_mask_for_address((uint16_t)(uintptr_t)&zx_init);
    mask |= bc__mem_mask_for_address((uint16_t)(uintptr_t)&bc_mem_initialized);
    mask |= bc__mem_mask_for_address(zx__mem_read_sp());
    return mask;
}

zx_status_t zx_init(void) {
    if (bc_mem_active_window_lease || bc_video_operation_depth) return ZX_BUSY;
    if (bc__mem_readback_is_unsafe(bc_mem_readback_backend)) return ZX_UNSAFE_CONTEXT;

    /* A caller override is useful for overlays with code or resident data in
     * additional windows. Otherwise protect the library's code/state and the
     * current stack window. */
    if (!bc_mem_pinned_window_override)
        bc_mem_pinned_window_mask = bc__mem_calculate_pinned_windows();

    bc__mem_refresh_all_windows();
    bc_mem_initialized = 1;
    bc__video_invalidate_cache();
    return ZX_OK;
}
