#include "../internal.h"

void bc__video_invalidate_window(zx_window_t window) {
    uint8_t high = (uint8_t)((uintptr_t)window >> 8);
    uint8_t index;

    for (index = 0; index < ZX_DRAW_BUFFER_SLOTS; ++index) {
        bc__draw_buffer_t *buffer = &bc_video_prepared_buffers[index];
        if (buffer->window0_high == high || buffer->window1_high == high) {
            buffer->window0_high = 0;
            bc_video_bound_slots = 0;
        }
    }
    if (!bc_video_surface_selected || bc_video_page0_base == (uintptr_t)window ||
        bc_video_page1_base == (uintptr_t)window)
        bc__video_invalidate_draw_cache();
}
