#include "../internal.h"

static zx_status_t acquire_ram(zx_window_t window, zx_ram_page_t page, void *lease) {
    bc_window_config_t mapping = {BC_RAM, page, 0, 0};
    return bc_window_acquire(window, mapping, lease);
}

static zx_status_t release_ram(void *lease) {
    return bc_window_release(lease);
}

static uint8_t window_busy(void) {
    return bc_mem_active_window_lease != 0;
}

static const struct zx_ram_heap_backend backend = {acquire_ram, release_ram, window_busy};

zx_status_t bc_ram_heap_init(zx_ram_heap_t *heap, zx_ram_page_pool_t *pool,
                             zx_ram_heap_page_t *page_storage, uint16_t page_capacity,
                             zx_window_t window, bc_window_lease_t *lease) {
    zx_status_t status;
    if (window < ZX_WINDOW_1 || window > ZX_WINDOW_3) return ZX_INVALID_ARGUMENT;
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease || (bc_mem_pinned_window_mask & (1u << window))) return ZX_BUSY;

    status = zx__ram_heap_init(heap, pool, page_storage, page_capacity, window, &backend, lease);
    if (status == ZX_OK) lease->active = 0;
    return status;
}
