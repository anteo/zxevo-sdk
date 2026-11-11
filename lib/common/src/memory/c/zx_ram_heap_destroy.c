#include "../internal.h"

zx_status_t zx_ram_heap_destroy(zx_ram_heap_t *heap) {
    uint16_t i;

    if (!heap || !heap->pool || !heap->pages) return ZX_INVALID_ARGUMENT;
    if (heap->mapping_state != ZX_RAM_HEAP_UNMAPPED || heap->backend->busy()) return ZX_BUSY;

    for (i = 0; i < heap->page_capacity; ++i) {
        zx_ram_heap_page_t *page = &heap->pages[i];
        if (page->state != ZX_RAM_HEAP_PAGE_FREE) {
            zx_status_t status = zx_ram_page_free(heap->pool, page->page);
            if (status != ZX_OK) return status;
            page->state = ZX_RAM_HEAP_PAGE_FREE;
            page->allocator = 0L;
        }
    }

    heap->pool = 0;
    heap->pages = 0;
    heap->page_capacity = 0;
    return ZX_OK;
}
