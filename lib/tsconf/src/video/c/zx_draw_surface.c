#include "../internal.h"
#include <tsconf/memory.h>
#include "../../../../common/src/memory/internal.h"

extern ts_window_lease_t *ts__memory_window_owner;

zx_status_t zx_draw_surface(const zx_video_surface_t *surface, zx_window_t window0,
                                   zx_window_t window1) {
    ts__draw_surface_t target;
    zx_status_t status;
    uint8_t layout;

    if (!surface || surface->page1 || window1 || !ZX__WINDOW_VALID(window0))
        return ZX_INVALID_ARGUMENT;
    target.mode = surface->mode;
    target.page = surface->page0;
    target.base = window0;
    layout = (uint8_t)(target.mode & 3u);
    if (layout == 1 || layout == 2) {
        if (window0) return ZX_INVALID_ARGUMENT;
        return ts__video_select_draw_surface(&target);
    }

    if (!window0) return ZX_INVALID_ARGUMENT;
    status = ts__video_check_mode(target.mode);
    if (status != ZX_OK) return status;
    if (ts__memory_window_owner) return ZX_BUSY;
    if (!((window0 == ZX_WINDOW_2 && ts_memory_get_page2() == target.page) ||
          (window0 == ZX_WINDOW_3 && ts_memory_get_page3() == target.page))) {
        if ((zx__mem_read_sp() >> 14) == ZX__WINDOW_INDEX(window0)) return ZX_BUSY;
        status = ts_map_ram_page(window0, target.page);
        if (status != ZX_OK) return status;
    }
    return ts__video_select_draw_surface(&target);
}
