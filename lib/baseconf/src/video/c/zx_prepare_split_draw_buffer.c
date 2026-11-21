#include "../internal.h"

zx_status_t zx_prepare_split_draw_buffer(uint8_t slot, uint16_t mode, zx_ram_page_t page0,
                                         zx_window_t window0, zx_ram_page_t page1,
                                         zx_window_t window1) {
    zx_status_t status;
    if (slot >= ZX_DRAW_BUFFER_SLOTS || !window1) return ZX_INVALID_ARGUMENT;
    status = bc__video_prepare_draw_buffer(&bc_video_prepared_buffers[slot], mode, page0,
                                           window0, page1, window1,
                                           &bc_video_prepared_buffers[slot ^ 1u]);
    if (status == ZX_OK) bc__video_refresh_display_buffers();
    return status;
}
