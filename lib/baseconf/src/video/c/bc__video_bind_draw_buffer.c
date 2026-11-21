#include "../internal.h"
#include "../../memory/internal.h"

/* Used only by the slot selector. Each entry points to physical_page in the
 * active memory map. Changing the map invalidates both slots. */
zx_ram_page_t *bc_video_slot_banks[ZX_DRAW_BUFFER_SLOTS][2];

/* On first selection, establish the format and check pins that may have been
 * changed since prepare. A pinned page stays resident until pins change. */
zx_status_t bc__video_bind_draw_buffer(const bc__draw_buffer_t *slot) __z88dk_fastcall {
    uint8_t index = slot != bc_video_prepared_buffers;
    uint8_t w0 = slot->window0_high >> 6, w1 = slot->window1_high >> 6;
    bc_window_config_t *map = bc_mem_window_cache[bc_mem_active_map];
    uint8_t pins = bc_mem_pinned_window_mask;
    if (!slot->window0_high) return ZX_UNAVAILABLE;
    if (bc_mem_active_window_lease || bc_video_operation_depth) return ZX_BUSY;
    if (((pins & (1u << w0)) && map[w0].physical_page != slot->page0) ||
        ((pins & (1u << w1)) && map[w1].physical_page != slot->page1))
        return ZX_BUSY;

    if (!bc_video_surface_selected || !bc_video_cache_valid ||
        bc_video_draw_surface_state.mode != slot->mode)
        bc__video_publish_draw_buffer(slot);
    bc_video_slot_banks[index][0] = &map[w0].physical_page;
    bc_video_slot_banks[index][1] = &map[w1].physical_page;
    bc_video_bound_slots |= 1u << index;
    return ZX_OK;
}
