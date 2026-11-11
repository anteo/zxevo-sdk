#include <malloc.h>
#include "../internal.h"

/* Leave offset zero on a miss. The status describes page acquisition.
 * The named heap reserves a header, so a valid offset is nonzero. */
static zx_status_t try_page(zx_ram_heap_t *heap, zx_ram_heap_page_t *page, uint16_t size,
                            uint16_t *offset) {
    void *base_address;
    void *block;
    zx_status_t status = zx__ram_heap_map_page(heap, page->page, 0, &base_address);
    if (status != ZX_OK) return status;

    if (page->state == ZX_RAM_HEAP_PAGE_FREE) {
        uint16_t region_size = ZX_RAM_PAGE_SIZE;
        /* Keep the end pointer away from 0 when W3 wraps past 0xffff. */
        if (heap->window == ZX_WINDOW_3) region_size -= 4u;
        HeapCreate(&page->allocator);
        HeapSbrk(&page->allocator, base_address, region_size);
        page->state = ZX_RAM_HEAP_PAGE_READY;
    }

    block = HeapAlloc(&page->allocator, size);
    if (block) *offset = (uint16_t)((uintptr_t)block - (uintptr_t)base_address);
    (void)zx_ram_heap_unmap(heap);
    return ZX_OK;
}

zx_status_t zx_ram_heap_alloc(zx_ram_heap_t *heap, uint16_t size, zx_ram_heap_ptr_t *pointer) {
    uint16_t i;
    uint16_t maximum_size = ZX_RAM_PAGE_SIZE - 4u;
    uint16_t offset = 0;
    zx_ram_heap_page_t *page;
    zx_ram_heap_page_t *free_page = 0;
    zx_status_t status;

    if (!heap || !heap->pool || !heap->pages || !pointer || !size || !heap->page_capacity ||
        heap->window < ZX_WINDOW_1 || heap->window > ZX_WINDOW_3)
        return ZX_INVALID_ARGUMENT;
    if (heap->mapping_state != ZX_RAM_HEAP_UNMAPPED) return ZX_BUSY;
    if (heap->window == ZX_WINDOW_3) maximum_size -= 4u;
    if (size > maximum_size) return ZX_UNAVAILABLE;

    for (i = 0; i < heap->page_capacity; ++i) {
        page = &heap->pages[i];
        if (page->state != ZX_RAM_HEAP_PAGE_FREE) {
            status = try_page(heap, page, size, &offset);
            if (status != ZX_OK) return status;
            if (offset) goto allocated;
            if (heap->mapping_state == ZX_RAM_HEAP_MAPPED) return ZX_UNAVAILABLE;
        } else if (!free_page) {
            free_page = page;
        }
    }

    if (!free_page) return ZX_UNAVAILABLE;
    page = free_page;
    status = zx_ram_page_alloc(heap->pool, &page->page);
    if (status != ZX_OK) return status;
    status = try_page(heap, page, size, &offset);
    if (!offset) {
        if (heap->mapping_state == ZX_RAM_HEAP_UNMAPPED) {
            zx_status_t released = zx_ram_page_free(heap->pool, page->page);
            if (released != ZX_OK) return released;
            page->state = ZX_RAM_HEAP_PAGE_FREE;
        }
        return status == ZX_OK ? ZX_UNAVAILABLE : status;
    }

allocated:
    pointer->page = page->page;
    pointer->offset = offset;
    return ZX_OK;
}
