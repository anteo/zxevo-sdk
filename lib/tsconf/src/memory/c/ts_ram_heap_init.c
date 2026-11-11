#include <tsconf/memory.h>
#include "../../../../common/src/memory/internal.h"

extern ts_window_lease_t *ts__memory_window_owner;

static zx_status_t acquire_ram(zx_window_t window, zx_ram_page_t page, void *lease) {
    return ts_window_acquire(window, page, lease);
}

static zx_status_t release_ram(void *lease) {
    return ts_window_release(lease);
}

static uint8_t window_busy(void) {
    return ts__memory_window_owner != 0;
}

static const struct zx_ram_heap_backend backend = {acquire_ram, release_ram, window_busy};

zx_status_t ts_ram_heap_init(zx_ram_heap_t *heap, zx_ram_page_pool_t *pool,
                             zx_ram_heap_page_t *page_storage, uint16_t page_capacity,
                             zx_window_t window, ts_window_lease_t *lease) {
    zx_status_t status;
    if (window > ZX_WINDOW_3) return ZX_INVALID_ARGUMENT;
    if (window < ZX_WINDOW_2) return ZX_UNSUPPORTED;
    if (ts__memory_window_owner) return ZX_BUSY;

    status = zx__ram_heap_init(heap, pool, page_storage, page_capacity, window, &backend, lease);
    if (status == ZX_OK) lease->active = 0;
    return status;
}
