#ifndef TSCONF_MEMORY_H
#define TSCONF_MEMORY_H

#include <stdint.h>
#include <zx/memory.h>
#include <zx/status.h>

#define TS_MEM_W0_WRITE 0x02u
#define TS_MEM_W0_DIRECT 0x04u
#define TS_MEM_W0_RAM 0x08u

typedef struct {
    zx_window_t window;
    uint8_t previous_page;
    uint8_t active;
} ts_window_lease_t;

/* Map physical RAM page 0..255 into W1..W3. W0 returns ZX_UNSUPPORTED
 * because MemConfig controls its ROM/RAM selection. An invalid window
 * returns ZX_INVALID_ARGUMENT. An active window lease returns ZX_BUSY.
 * The caller keeps code, stack, data and IRQ handlers outside the window. */
zx_status_t ts_map_ram_page(zx_window_t window, zx_ram_page_t page);

/* Save and temporarily replace the page in W2 or W3. These are the windows
 * with register readback. W0/W1 return ZX_UNSUPPORTED. Invalid arguments
 * return ZX_INVALID_ARGUMENT. Another active lease returns ZX_BUSY.
 * Keep lease and needed memory resident. Serialize with other paging users,
 * including packed drawing (W3), TS-BIOS (W2) and direct register writes. */
zx_status_t ts_window_acquire(zx_window_t window, zx_ram_page_t page, ts_window_lease_t *lease);
/* Restore the saved page and invalidate the lease. NULL or inactive leases
 * return ZX_INVALID_ARGUMENT. A different active handle returns ZX_BUSY.
 * Use the same lease object at the same address, with its fields unchanged. */
zx_status_t ts_window_release(ts_window_lease_t *lease);

/* Set up a banked heap for W2 or W3 with caller-owned page storage and a
 * dedicated lease object. Keep the heap, pool, page storage and lease
 * resident and follow the paging constraints of ts_window_acquire. */
zx_status_t ts_ram_heap_init(zx_ram_heap_t *heap, zx_ram_page_pool_t *pool,
                             zx_ram_heap_page_t *page_storage, uint16_t page_capacity,
                             zx_window_t window, ts_window_lease_t *lease);

/* Set the Page0 register. This is deliberately separate from RAM mapping:
 * MemConfig determines whether W0 selects a ROM or RAM page. Keep code,
 * data, stack and IRQ handlers outside W0 across a remap. */
void ts_memory_set_page0(uint8_t page) __z88dk_fastcall;

/* Only Page2 and Page3 provide paging register readback on stock hardware. */
uint8_t ts_memory_get_page2(void);
uint8_t ts_memory_get_page3(void);

/* Write MemConfig, including W0 mapping and legacy 7FFD paging mode.
 * Keep code and stack outside W0 when changing its mapping. */
void ts_memory_set_config(uint8_t config) __z88dk_fastcall;

/* Write CacheConfig. Bits 0..3 enable the cache in W0..W3, respectively.
 * Keep CPU aliases of DMA buffers uncached. Changing the mask does not
 * flush existing cache tags. This call records the mask for zx_set_cpu_speed. */
void ts_memory_set_cache(uint8_t mask) __z88dk_fastcall;

#endif
