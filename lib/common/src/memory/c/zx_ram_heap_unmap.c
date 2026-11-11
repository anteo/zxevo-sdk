#include "../internal.h"

zx_status_t zx_ram_heap_unmap(zx_ram_heap_t *heap) {
    zx_status_t status;
    if (!heap || !heap->pool || !heap->pages) return ZX_INVALID_ARGUMENT;
    if (heap->mapping_state == ZX_RAM_HEAP_UNMAPPED) return ZX_OK;
    status = heap->backend->release(heap->lease);
    if (status == ZX_OK) heap->mapping_state = ZX_RAM_HEAP_UNMAPPED;
    return status;
}
