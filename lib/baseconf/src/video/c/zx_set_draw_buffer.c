#include "../internal.h"

zx_status_t zx_set_draw_buffer(uint16_t mode, zx_ram_page_t page, zx_window_t window) {
    bc__draw_buffer_t buffer;
    zx_status_t status = bc__video_prepare_draw_buffer(&buffer, mode, page, window, 0, NULL, NULL);
    return status == ZX_OK ? bc__video_publish_draw_buffer(&buffer) : status;
}
