#include "../internal.h"

zx_status_t zx_ram_heap_map(zx_ram_heap_t *heap, zx_ram_heap_ptr_t pointer, void **address) {
    uint16_t i;

    if (!heap || !heap->pool || !heap->pages || !address || pointer.offset >= ZX_RAM_PAGE_SIZE ||
        heap->window < ZX_WINDOW_1 || heap->window > ZX_WINDOW_3)
        return ZX_INVALID_ARGUMENT;
    if (heap->mapping_state != ZX_RAM_HEAP_UNMAPPED) return ZX_BUSY;

    for (i = 0; i < heap->page_capacity; ++i) {
        zx_ram_heap_page_t *page = &heap->pages[i];
        if (page->state == ZX_RAM_HEAP_PAGE_READY && page->page == pointer.page)
            return zx__ram_heap_map_page(heap, page->page, pointer.offset, address);
    }

    return ZX_INVALID_ARGUMENT;
}
