#include "../internal.h"

zx_status_t zx_set_split_draw_buffer(uint16_t mode, zx_ram_page_t page0, zx_window_t window0,
                                     zx_ram_page_t page1, zx_window_t window1) {
    bc__draw_buffer_t buffer;
    zx_status_t status;
    if (!window1) return ZX_INVALID_ARGUMENT;
    status = bc__video_prepare_draw_buffer(&buffer, mode, page0, window0, page1, window1, NULL);
    return status == ZX_OK ? bc__video_publish_draw_buffer(&buffer) : status;
}
