#include <malloc.h>
#include "../internal.h"

zx_status_t zx_ram_heap_free(zx_ram_heap_t *heap, zx_ram_heap_ptr_t pointer) {
    void *address;
    zx_status_t status;
    uint16_t i;

    if (!heap || !heap->pool || !heap->pages || pointer.offset >= ZX_RAM_PAGE_SIZE)
        return ZX_INVALID_ARGUMENT;
    if (heap->mapping_state != ZX_RAM_HEAP_UNMAPPED) return ZX_BUSY;

    for (i = 0; i < heap->page_capacity; ++i) {
        zx_ram_heap_page_t *page = &heap->pages[i];
        if (page->state == ZX_RAM_HEAP_PAGE_READY && page->page == pointer.page) {
            status = zx__ram_heap_map_page(heap, page->page, pointer.offset, &address);
            if (status != ZX_OK) return status;
            HeapFree(&page->allocator, address);
            (void)zx_ram_heap_unmap(heap);
            return ZX_OK;
        }
    }

    return ZX_INVALID_ARGUMENT;
}
