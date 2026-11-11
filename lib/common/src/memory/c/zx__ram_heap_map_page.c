#include "../internal.h"

zx_status_t zx__ram_heap_map_page(zx_ram_heap_t *heap, zx_ram_page_t page, uint16_t offset,
                                  void **address) {
    zx_status_t status = heap->backend->acquire(heap->window, page, heap->lease);
    if (status != ZX_OK) return status;

    heap->mapping_state = ZX_RAM_HEAP_MAPPED;
    *address = (void *)((uint16_t)heap->window * ZX_RAM_PAGE_SIZE + offset);
    return ZX_OK;
}
