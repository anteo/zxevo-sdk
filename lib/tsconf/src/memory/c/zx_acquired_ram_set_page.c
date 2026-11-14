#include <tsconf.h>
#include "../internal.h"

extern ts_window_lease_t *ts__memory_window_owner;

zx_status_t zx_acquired_ram_set_page(zx_ram_lease_t *lease, zx_ram_page_t page) {
    ts_window_lease_t *native = (ts_window_lease_t *)lease;
    if (!lease || !native->active) return ZX_INVALID_ARGUMENT;
    if (ts__memory_window_owner != native) return ZX_BUSY;
    if (native->window == ZX_WINDOW_2)
        ts_memory_set_page2(page);
    else if (native->window == ZX_WINDOW_3)
        ts_memory_set_page3(page);
    else
        return ZX_UNSUPPORTED;
    return ZX_OK;
}
