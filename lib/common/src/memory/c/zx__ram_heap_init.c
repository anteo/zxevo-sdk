#include "../internal.h"

zx_status_t zx__ram_heap_init(zx_ram_heap_t *heap, zx_ram_page_pool_t *pool,
                              zx_ram_heap_page_t *pages, uint16_t capacity, zx_window_t window,
                              const struct zx_ram_heap_backend *backend, void *lease) {
    uint16_t i;

    if (!heap || !pool || !pool->page_mask || !pages || !capacity || capacity > ZX_RAM_PAGE_COUNT ||
        !lease)
        return ZX_INVALID_ARGUMENT;

    heap->pool = pool;
    heap->pages = pages;
    heap->page_capacity = capacity;
    heap->window = window;
    heap->backend = backend;
    heap->lease = lease;
    heap->mapping_state = ZX_RAM_HEAP_UNMAPPED;

    for (i = 0; i < capacity; ++i) {
        pages[i].allocator = 0L;
        pages[i].page = 0;
        pages[i].state = ZX_RAM_HEAP_PAGE_FREE;
    }

    return ZX_OK;
}
