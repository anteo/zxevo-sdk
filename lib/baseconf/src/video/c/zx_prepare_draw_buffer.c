#include "../internal.h"

zx_status_t zx_prepare_draw_buffer(uint8_t slot, uint16_t mode, zx_ram_page_t page,
                                   zx_window_t window) {
    zx_status_t status;
    if (slot >= ZX_DRAW_BUFFER_SLOTS) return ZX_INVALID_ARGUMENT;
    status = bc__video_prepare_draw_buffer(&bc_video_prepared_buffers[slot], mode, page, window, 0,
                                           NULL, &bc_video_prepared_buffers[slot ^ 1u]);
    if (status == ZX_OK) bc__video_refresh_display_buffers();
    return status;
}
