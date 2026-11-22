#include "../internal.h"

zx_status_t zx_prepare_draw_buffer(uint8_t slot, uint16_t mode, zx_ram_page_t page,
                                   zx_window_t window) {
    if (slot >= ZX_DRAW_BUFFER_SLOTS) return ZX_INVALID_ARGUMENT;
    return ts__video_prepare_draw_buffer(&ts_video_prepared_buffers[slot], mode, page, window);
}
