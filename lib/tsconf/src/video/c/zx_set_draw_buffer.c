#include "../internal.h"
#include <tsconf/memory.h>
#include "../../../../common/src/memory/internal.h"

extern ts_window_lease_t *ts__memory_window_owner;
extern uint8_t ts_draw_config, ts_draw_base;
extern uint8_t ts__draw_window_leased;
extern zx_ram_page_t ts_draw_page;

static zx_status_t prepare_draw_buffer(ts__draw_buffer_t *buffer, uint16_t mode,
                                       zx_ram_page_t page, zx_window_t window) {
    zx_status_t status;
    uint8_t layout = (uint8_t)(mode & 3u);
    uint8_t packed = layout == 1 || layout == 2;
    uint8_t window_high = (uint8_t)((uintptr_t)window >> 8);

    if (!ZX__WINDOW_VALID(window) || packed != !window) return ZX_INVALID_ARGUMENT;
    status = ts__video_check_mode(mode);
    if (status != ZX_OK) return status;

    if (packed) {
        if (page & (layout == 1 ? 7u : 15u)) return ZX_INVALID_ARGUMENT;
    } else {
        if (ts__memory_window_owner) return ZX_BUSY;
        if (!((window == ZX_WINDOW_2 && ts_memory_get_page2() == page) ||
              (window == ZX_WINDOW_3 && ts_memory_get_page3() == page))) {
            if (ZX__WINDOW_BASE(zx__mem_read_sp()) == window) return ZX_BUSY;
            status = ts_map_ram_page(window, page);
            if (status != ZX_OK) return status;
            if (ts_draw_base == window_high && ts_draw_page != page) ts_draw_config = 0xff;
        }
    }
    buffer->config = (uint8_t)mode;
    buffer->page = page;
    buffer->window_high = window_high;
    return ZX_OK;
}

zx_status_t zx_prepare_draw_buffer(uint8_t slot, uint16_t mode, zx_ram_page_t page,
                                   zx_window_t window) {
    if (slot >= ZX_DRAW_BUFFER_SLOTS) return ZX_INVALID_ARGUMENT;
    return prepare_draw_buffer(&ts_video_prepared_buffers[slot], mode, page, window);
}

zx_status_t zx_set_draw_buffer(uint16_t mode, zx_ram_page_t page, zx_window_t window) {
    ts__draw_buffer_t target;
    zx_status_t status = prepare_draw_buffer(&target, mode, page, window);
    if (status != ZX_OK) return status;
    /* Only a packed target can replace the current target while a lease is active. */
    status = ts__video_commit_draw_buffer(&target);
    ts__draw_window_leased = 0;
    return status;
}
