#ifndef ZX_MEMORY_H
#define ZX_MEMORY_H

#include <stdint.h>
#include <zx/status.h>

/* The four consecutive 16 KiB windows in the Z80 address space. */
typedef enum { ZX_WINDOW_0 = 0, ZX_WINDOW_1 = 1, ZX_WINDOW_2 = 2, ZX_WINDOW_3 = 3 } zx_window_t;

typedef uint8_t zx_ram_page_t;

/* Private storage for a temporary RAM-window mapping. Keep this object at
 * the same resident address until zx_release_ram succeeds. */
typedef struct {
    uint8_t state[16];
} zx_ram_lease_t;

/* Save the current mapping and install a physical RAM page in window W0..W3.
 * The platform may reject windows whose mapping cannot be read back or whose
 * resident contents are pinned. TSConf supports W2/W3; BaseConf supports any
 * unpinned window after zx_init. Code, stack, lease and needed data must stay
 * outside the mapped window. Only one lease may be active per platform. */
zx_status_t zx_acquire_ram(zx_window_t window, zx_ram_page_t page, zx_ram_lease_t *lease);
/* Replace the page in the same acquired window without losing its original
 * mapping. A foreign or inactive lease returns ZX_BUSY/ZX_INVALID_ARGUMENT. */
zx_status_t zx_acquired_ram_set_page(zx_ram_lease_t *lease, zx_ram_page_t page);
/* Restore the mapping saved at acquisition. Keep the lease resident and retry
 * on a restoration error; it remains active until this returns ZX_OK. */
zx_status_t zx_release_ram(zx_ram_lease_t *lease);

#define ZX_RAM_PAGE_SIZE 0x4000u
#define ZX_RAM_PAGE_COUNT 256u
#define ZX_RAM_PAGE_MASK_SIZE (ZX_RAM_PAGE_COUNT / 8u)

typedef uint8_t zx_ram_page_mask_t[ZX_RAM_PAGE_MASK_SIZE];

typedef struct {
    const uint8_t *page_mask;
    uint8_t allocated[ZX_RAM_PAGE_MASK_SIZE];
} zx_ram_page_pool_t;

/* Far references are handles, not C pointers. offset is within one 16 KiB page. */
typedef struct {
    zx_ram_page_t page;
    uint16_t offset;
} zx_ram_heap_ptr_t;

/* Resident storage for one z88dk named heap backed by a physical page. */
typedef struct {
    long allocator;
    zx_ram_page_t page;
    uint8_t state;
} zx_ram_heap_page_t;

struct zx_ram_heap_backend;

typedef enum {
    ZX_RAM_HEAP_UNMAPPED,
    ZX_RAM_HEAP_MAPPED,
    ZX_RAM_HEAP_RESTORE_PENDING
} zx_ram_heap_mapping_state_t;

/* Initialize with bc_ram_heap_init or ts_ram_heap_init. Keep the heap, pool,
 * page storage and dedicated lease resident. Treat their heap-owned fields as
 * private, and restore the window through zx_ram_heap_unmap. */
typedef struct {
    zx_ram_page_pool_t *pool;
    zx_ram_heap_page_t *pages;
    uint16_t page_capacity;
    zx_window_t window;
    const struct zx_ram_heap_backend *backend;
    void *lease;
    zx_ram_heap_mapping_state_t mapping_state;
} zx_ram_heap_t;

/* Initialize a pool from a 32-byte mask for all 256 RAM pages. Bit N set
 * means page N is available to the pool; clear bits reserve/exclude pages.
 * The allocation bitmap is kept inside pool. Keep page_mask CPU-accessible,
 * valid and unchanged for the pool's lifetime. The caller chooses safe pages. */
zx_status_t zx_ram_page_pool_init(zx_ram_page_pool_t *pool, const zx_ram_page_mask_t page_mask);
/* Claim the first free page in the pool. Returns ZX_UNAVAILABLE when exhausted. */
zx_status_t zx_ram_page_alloc(zx_ram_page_pool_t *pool, zx_ram_page_t *page);
/* Return a page previously claimed from this pool. Unknown or already free pages
 * return ZX_INVALID_ARGUMENT. This only updates the pool bitmap; it does not map
 * the page or clear its contents. */
zx_status_t zx_ram_page_free(zx_ram_page_pool_t *pool, zx_ram_page_t page);

/* Allocate one block within a page. Write the handle on ZX_OK and leave it
 * unchanged on error. Check zx_ram_heap_restore_pending after the call. */
zx_status_t zx_ram_heap_alloc(zx_ram_heap_t *heap, uint16_t size, zx_ram_heap_ptr_t *pointer);
/* Return a live block to its page heap. ZX_OK means the block was freed.
 * Check zx_ram_heap_restore_pending after the call. */
zx_status_t zx_ram_heap_free(zx_ram_heap_t *heap, zx_ram_heap_ptr_t pointer);
/* Return nonzero after a failed window restore. Retry zx_ram_heap_unmap
 * before starting another operation. The allocation/free result is independent. */
uint8_t zx_ram_heap_restore_pending(const zx_ram_heap_t *heap) __z88dk_fastcall;
/* Map a block into the heap's window and return its CPU address. Keep the heap
 * and lease resident. The returned pointer is valid until zx_ram_heap_unmap(). */
zx_status_t zx_ram_heap_map(zx_ram_heap_t *heap, zx_ram_heap_ptr_t pointer, void **address);
/* Restore the previous window mapping. A failed release leaves the lease active
 * so this function can be retried. */
zx_status_t zx_ram_heap_unmap(zx_ram_heap_t *heap);
/* Return all backing pages to pool and invalidate every handle from this heap.
 * The caller must ensure no blocks are still needed. */
zx_status_t zx_ram_heap_destroy(zx_ram_heap_t *heap);

#endif
