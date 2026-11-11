#include <baseconf.h>

#include "bc_case.h"

enum { FIRST_PAGE = 46, SECOND_PAGE = 63, SCRATCH_PAGE = 53, BLOCK_SIZE = 0x2800 };

static const zx_ram_page_mask_t page_mask = {0, 0, 0, 0, 0, 0x40, 0, 0x80};
static zx_ram_page_pool_t pool;
static zx_ram_heap_t heap;
static zx_ram_heap_page_t pages[2];
static bc_window_lease_t lease;
static volatile uint8_t *const scratch = (volatile uint8_t *)0xc123u;

static uint8_t scratch_is_restored(void) {
    bc_window_config_t config;
    bc_map_t map = bc_get_active_map();
    return bc_get_window_config(map, ZX_WINDOW_3, &config) == ZX_OK && config.kind == BC_RAM &&
           config.physical_page == SCRATCH_PAGE && config.write_protected == 0 && *scratch == 0x8e;
}

static zx_status_t map_block(zx_ram_heap_ptr_t block, void **address) {
    zx_status_t status = zx_ram_heap_map(&heap, block, address);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return status;
    if (block.offset > ZX_RAM_PAGE_SIZE - BLOCK_SIZE ||
        (uint16_t)(uintptr_t)*address != 0xc000u + block.offset) {
        ZX_ASSERT(block.offset <= ZX_RAM_PAGE_SIZE - BLOCK_SIZE &&
                  (uint16_t)(uintptr_t)*address == 0xc000u + block.offset);
        (void)zx_ram_heap_unmap(&heap);
        return ZX_UNSAFE_CONTEXT;
    }
    return ZX_OK;
}

static void write_block(zx_ram_heap_ptr_t block, uint8_t first, uint8_t last) {
    void *address;
    if (map_block(block, &address) != ZX_OK) return;
    ((volatile uint8_t *)address)[0] = first;
    ((volatile uint8_t *)address)[BLOCK_SIZE - 1] = last;
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    ZX_ASSERT(scratch_is_restored());
}

static void check_block(zx_ram_heap_ptr_t block, uint8_t first, uint8_t last) {
    void *address;
    if (map_block(block, &address) != ZX_OK) return;
    ZX_ASSERT(((volatile uint8_t *)address)[0] == first);
    ZX_ASSERT(((volatile uint8_t *)address)[BLOCK_SIZE - 1] == last);
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    ZX_ASSERT(scratch_is_restored());
}

static void check_banked_heap(void) {
    zx_ram_heap_ptr_t first, second;
    zx_ram_heap_ptr_t extra = {0xff, 0xffff};
    zx_ram_page_t page = 0;
    uint8_t pinned = bc_get_pinned_windows();
    void *address;
    void *blocked_address;
    zx_status_t status;
    zx_status_t result;

    ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, SCRATCH_PAGE) == ZX_OK);
    *scratch = 0x8e;
    ZX_ASSERT(zx_ram_page_pool_init(&pool, page_mask) == ZX_OK);
    ZX_ASSERT(bc_ram_heap_init(&heap, &pool, pages, 2, ZX_WINDOW_0, &lease) == ZX_INVALID_ARGUMENT);
    status = bc_ram_heap_init(&heap, &pool, pages, 2, ZX_WINDOW_3, &lease);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;

    bc_set_pinned_windows(pinned | (1u << ZX_WINDOW_3));
    result = zx_ram_heap_alloc(&heap, BLOCK_SIZE, &extra);
    bc_set_pinned_windows(pinned);
    ZX_ASSERT(result == ZX_BUSY && extra.page == 0xff && extra.offset == 0xffff);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &page) == ZX_OK && page == FIRST_PAGE);
    ZX_ASSERT(zx_ram_page_free(&pool, page) == ZX_OK);

    ZX_ASSERT(zx_ram_heap_alloc(&heap, ZX_RAM_PAGE_SIZE, &extra) == ZX_UNAVAILABLE);
    result = zx_ram_heap_alloc(&heap, BLOCK_SIZE, &first);
    ZX_ASSERT(result == ZX_OK);
    if (result != ZX_OK) return;
    result = zx_ram_heap_alloc(&heap, BLOCK_SIZE, &second);
    ZX_ASSERT(result == ZX_OK);
    if (result != ZX_OK) return;
    ZX_ASSERT(first.page == FIRST_PAGE && second.page == SECOND_PAGE);
    ZX_ASSERT(zx_ram_heap_alloc(&heap, BLOCK_SIZE, &extra) == ZX_UNAVAILABLE);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &page) == ZX_UNAVAILABLE);
    ZX_ASSERT(scratch_is_restored());
    zx_test_step_marker("grow");

    write_block(first, 0x19, 0x5c);
    write_block(second, 0xb3, 0xe7);
    check_block(first, 0x19, 0x5c);
    if (map_block(second, &address) != ZX_OK) return;
    ZX_ASSERT(zx_ram_heap_map(&heap, first, &blocked_address) == ZX_BUSY);
    ZX_ASSERT(zx_ram_heap_alloc(&heap, 16, &extra) == ZX_BUSY);
    ZX_ASSERT(zx_ram_heap_free(&heap, first) == ZX_BUSY);
    ZX_ASSERT(zx_ram_heap_destroy(&heap) == ZX_BUSY);
    ZX_ASSERT(((volatile uint8_t *)address)[0] == 0xb3);
    ZX_ASSERT(((volatile uint8_t *)address)[BLOCK_SIZE - 1] == 0xe7);
    bc_set_pinned_windows(pinned | (1u << ZX_WINDOW_3));
    status = zx_ram_heap_unmap(&heap);
    bc_set_pinned_windows(pinned);
    ZX_ASSERT(status == ZX_BUSY && lease.active);
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    ZX_ASSERT(zx_ram_heap_unmap(&heap) == ZX_OK);
    ZX_ASSERT(scratch_is_restored());
    zx_test_step_marker("isolation");

    ZX_ASSERT(zx_ram_heap_free(&heap, first) == ZX_OK);
    result = zx_ram_heap_alloc(&heap, BLOCK_SIZE, &extra);
    ZX_ASSERT(result == ZX_OK);
    if (result != ZX_OK) return;
    ZX_ASSERT(extra.page == FIRST_PAGE);
    write_block(extra, 0x35, 0xc6);
    check_block(second, 0xb3, 0xe7);
    check_block(extra, 0x35, 0xc6);
    ZX_ASSERT(zx_ram_heap_free(&heap, extra) == ZX_OK);
    ZX_ASSERT(zx_ram_heap_free(&heap, second) == ZX_OK);
    ZX_ASSERT(zx_ram_heap_destroy(&heap) == ZX_OK);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &page) == ZX_OK && page == FIRST_PAGE);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &page) == ZX_OK && page == SECOND_PAGE);
    ZX_ASSERT(zx_ram_page_alloc(&pool, &page) == ZX_UNAVAILABLE);
    ZX_ASSERT(scratch_is_restored());
    zx_test_step_marker("reuse");
}

int main(void) {
    if (bc_case_init() == ZX_OK) check_banked_heap();
    zx_test_finish();
    return 0;
}
