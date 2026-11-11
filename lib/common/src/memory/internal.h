#ifndef ZX_MEMORY_INTERNAL_H
#define ZX_MEMORY_INTERNAL_H

#include <zx/memory.h>

#define ZX_RAM_HEAP_PAGE_FREE 0u
#define ZX_RAM_HEAP_PAGE_READY 1u

struct zx_ram_heap_backend {
    zx_status_t (*acquire)(zx_window_t window, zx_ram_page_t page, void *lease);
    zx_status_t (*release)(void *lease);
    uint8_t (*busy)(void);
};

zx_status_t zx__ram_heap_init(zx_ram_heap_t *heap, zx_ram_page_pool_t *pool,
                              zx_ram_heap_page_t *pages, uint16_t capacity, zx_window_t window,
                              const struct zx_ram_heap_backend *backend, void *lease);
/* The caller has selected a backing page and validated the offset and output. */
zx_status_t zx__ram_heap_map_page(zx_ram_heap_t *heap, zx_ram_page_t page, uint16_t offset,
                                  void **address);

uint16_t zx__mem_read_sp(void);

#endif
