#include "../internal.h"

extern uint8_t ts__draw_window_leased;

zx_status_t zx_set_draw_buffer(uint16_t mode, zx_ram_page_t page, zx_window_t window) {
    ts__draw_buffer_t target;
    zx_status_t status = ts__video_prepare_draw_buffer(&target, mode, page, window);
    if (status != ZX_OK) return status;
    /* Only a packed target can replace the current target while a lease is active. */
    status = ts__video_commit_draw_buffer(&target);
    ts__draw_window_leased = 0;
    return status;
}
