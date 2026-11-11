#include <zx_test.h>

#if defined(__BASECONF)
#include "bc_case.h"
#else
#include <tsconf/memory.h>
#endif

#define LARGE_BLOCK 0x2800u

static const zx_ram_page_mask_t page_mask = {0xC0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                             0x01, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x80};

static zx_ram_page_pool_t pool;
static zx_ram_heap_t heap;
static zx_ram_heap_page_t heap_pages[2];

#if defined(__BASECONF)
static bc_window_lease_t lease;

static zx_status_t init_heap(void) {
    return bc_ram_heap_init(&heap, &pool, heap_pages, 2, ZX_WINDOW_2, &lease);
}
#else
static ts_window_lease_t lease;

static zx_status_t init_heap(void) {
    return ts_ram_heap_init(&heap, &pool, heap_pages, 2, ZX_WINDOW_3, &lease);
}
#endif

static void check_memory(void) {
    zx_ram_page_t first = 0;
    zx_ram_page_t second = 0;
    zx_ram_page_t reclaimed = 0;
    zx_ram_page_t upper = 0;
    zx_ram_page_t last = 0;
    zx_ram_heap_ptr_t item;
    zx_ram_heap_ptr_t item2;
    zx_ram_heap_ptr_t item3;
    zx_status_t status;
    zx_status_t result;
    void *address;

    status = zx_ram_page_pool_init(&pool, page_mask);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto report;

    ZX_ASSERT(zx_ram_page_alloc(&pool, &first) == ZX_OK);
    ZX_ASSERT(first == 6);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &second) == ZX_OK);
    ZX_ASSERT(second == 7);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &upper) == ZX_OK && upper == 0x80);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &last) == ZX_OK && last == 0xff);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &reclaimed) == ZX_UNAVAILABLE);
    ZX_ASSERT(zx_ram_page_free(&pool, 0xff) == ZX_OK);
    ZX_ASSERT(zx_ram_page_free(&pool, 0xff) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &last) == ZX_OK && last == 0xff);
    ZX_ASSERT(zx_ram_page_free(&pool, last) == ZX_OK);
    ZX_ASSERT(zx_ram_page_free(&pool, upper) == ZX_OK);
    ZX_ASSERT(zx_ram_page_free(&pool, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_ram_page_free(&pool, first) == ZX_OK);
    ZX_ASSERT(zx_ram_page_free(&pool, first) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &reclaimed) == ZX_OK);
    ZX_ASSERT(reclaimed == first);
    ZX_ASSERT(zx_ram_page_free(&pool, reclaimed) == ZX_OK);
    ZX_ASSERT(zx_ram_page_free(&pool, second) == ZX_OK);
    zx_test_step_marker("pool");

    status = init_heap();
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto report;

    result = zx_ram_heap_alloc(&heap, LARGE_BLOCK, &item);
    ZX_ASSERT(result == ZX_OK);
    if (result != ZX_OK) {
        (void)zx_ram_heap_destroy(&heap);
        goto report;
    }

    result = zx_ram_heap_alloc(&heap, 32, &item2);
    ZX_ASSERT(result == ZX_OK);
    if (result != ZX_OK) {
        (void)zx_ram_heap_destroy(&heap);
        goto report;
    }
    ZX_ASSERT(item.page == item2.page);
    ZX_ASSERT(item.offset != item2.offset);
    result = zx_ram_heap_alloc(&heap, LARGE_BLOCK, &item3);
    ZX_ASSERT(result == ZX_OK);
    if (result != ZX_OK) goto report;
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    ZX_ASSERT(item.page == 6 && item2.page == 6 && item3.page == 7);
    if (item.page != 6 || item2.page != 6 || item3.page != 7) goto report;

    status = zx_ram_heap_map(&heap, item3, &address);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto report;
    ((volatile uint8_t *)address)[0] = 0xD3;
    ZX_ASSERT(zx_ram_heap_destroy(&heap) == ZX_BUSY);
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);

    status = zx_ram_heap_map(&heap, item, &address);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        (void)zx_ram_heap_destroy(&heap);
        goto report;
    }
    ((uint8_t *)address)[0] = 0x2A;
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);

    status = zx_ram_heap_map(&heap, item2, &address);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        (void)zx_ram_heap_destroy(&heap);
        goto report;
    }
    ((uint8_t *)address)[0] = 0xA7;
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);

    status = zx_ram_heap_map(&heap, item, &address);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        (void)zx_ram_heap_destroy(&heap);
        goto report;
    }
    ZX_ASSERT(((uint8_t *)address)[0] == 0x2A);
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    status = zx_ram_heap_map(&heap, item2, &address);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) {
        (void)zx_ram_heap_destroy(&heap);
        goto report;
    }
    ZX_ASSERT(((uint8_t *)address)[0] == 0xA7);
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    status = zx_ram_heap_map(&heap, item3, &address);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto report;
    ZX_ASSERT(((volatile uint8_t *)address)[0] == 0xD3);
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    ZX_ASSERT(zx_ram_heap_free(&heap, item) == ZX_OK);
    ZX_ASSERT(zx_ram_heap_free(&heap, item2) == ZX_OK);
    ZX_ASSERT(zx_ram_heap_free(&heap, item3) == ZX_OK);
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    ZX_ASSERT(zx_ram_heap_destroy(&heap) == ZX_OK);

    ZX_ASSERT(zx_ram_page_alloc(&pool, &reclaimed) == ZX_OK);
    ZX_ASSERT(reclaimed == first);
    ZX_ASSERT(zx_ram_page_free(&pool, reclaimed) == ZX_OK);

report:
    zx_test_step_marker("heap");
}

int main(void) {
#if defined(__BASECONF)
    if (bc_case_init() == ZX_OK) check_memory();
#else
    uint8_t previous_page;

    zx_test_init();
    previous_page = ts_memory_get_page3();
    check_memory();
    ZX_ASSERT(ts_memory_get_page3() == previous_page);
    ZX_ASSERT(!lease.active);
    zx_test_step_marker("restore");
#endif
    zx_test_finish();
    return 0;
}
