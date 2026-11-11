#ifndef BASECONF_MEMORY_H
#define BASECONF_MEMORY_H
#include <stdint.h>
#include <baseconf.h>

typedef struct {
    zx_window_t window;
    bc_window_config_t previous;
    uint8_t map;
    uint8_t active;
} bc_window_lease_t;

typedef struct {
    uint8_t saved_7ffd;
    uint8_t saved_eff7;
    uint8_t saved_xx77_data;
    uint16_t saved_xx77_address;
} bc_paging_snapshot_t;

/* Configure a 16 KiB window in map 0 or 1: RAM page 0..255 or Flash bank 0..31,
 * with substitution/write_protected flags exactly 0 or 1. Requires zx_init.
 * A pinned window, active window lease/video operation or paging lock returns
 * ZX_BUSY. Updating the other map temporarily selects it and then restores the
 * active map; pinned windows must match in both maps or ZX_UNSAFE_CONTEXT is
 * returned. Invalid arguments return ZX_INVALID_ARGUMENT. */
zx_status_t bc_configure_window(bc_map_t map, zx_window_t window,
                                const bc_window_config_t *configuration);
/* Return the live 7FFD map selection through the configured readback backend. */
bc_map_t bc_get_active_map(void);
/* Snapshot live 7FFD/EFF7 state and reconstruct the xx77 write address/data
 * from FPGA readback without changing paging. Requires zx_init and non-NULL state. */
zx_status_t bc_get_paging_state(bc_paging_snapshot_t *state);
/* Return the current software mask (bits 0..3 are W0..W3); no hardware readback
 * is performed and the mask is not checked against actual code/stack placement. */
uint8_t bc_get_pinned_windows(void);
/* Return the selected software backend without reading or validating hardware. */
bc_readback_backend_t bc_get_readback_backend(void);
/* Copy a cached map/window configuration. Requires zx_init and returns
 * ZX_INVALID_ARGUMENT for invalid map/window or NULL configuration.
 * Use bc_resync to refresh the cache after external paging changes. */
zx_status_t bc_get_window_config(bc_map_t map, zx_window_t window,
                                 bc_window_config_t *configuration);
/* Map Flash bank 0..31 into the active map's window, with substitution disabled
 * and write protection enabled. Other constraints/statuses follow bc_configure_window. */
zx_status_t bc_map_flash_bank(zx_window_t window, bc_flash_bank_t bank);
/* Map RAM page 0..255 into the active map's window, with substitution and write
 * protection disabled. Other constraints/statuses follow bc_configure_window. */
zx_status_t bc_map_ram_page(zx_window_t window, zx_ram_page_t page);
/* Read FPGA register index through the selected BD/BE backend. Returns the raw
 * byte without validating the index or checking hardware presence. No init required. */
uint8_t bc_readback_register(uint8_t index);
/* Refresh cached windows from FPGA readback and refresh the selected drawing
 * context. Call after changing paging outside the library. Requires zx_init;
 * returns ZX_BUSY during a window lease/video operation and may report that
 * the selected draw surface is no longer accessible. Does not remap RAM. */
zx_status_t bc_resync(void);
/* Select active FPGA map 0 or 1. Requires zx_init; switching requires matching
 * pinned windows in both maps (otherwise ZX_UNSAFE_CONTEXT). Returns ZX_BUSY
 * during a window lease/video operation or if the paging lock prevents switching. */
zx_status_t bc_select_map(bc_map_t map);
/* Set 7FFD's displayed-screen bit to 0 or 1 without changing the draw target.
 * Requires zx_init; returns ZX_BUSY if the 128K paging lock prevents a change. */
zx_status_t bc_select_screen(zx_screen_t screen);
/* Select 128 KiB (including the 7FFD lock bit) or 1024 KiB interpretation of
 * paging bits through EFF7. Requires zx_init; returns ZX_BUSY during video
 * operations and propagates errors when the register cannot be safely changed. */
zx_status_t bc_set_addressing(bc_addressing_t addressing);
/* Record whether the caller has prepared both memory maps. This only
 * changes software state: the library does not prepare or verify the maps.
 * Enabling the page manager returns ZX_UNAVAILABLE until this is nonzero.
 * Zero means unprepared. May be called before or after init. */
void bc_set_maps_prepared(uint8_t prepared);
/* Enable the FPGA page manager with a nonzero argument. Requires zx_init,
 * both maps declared prepared, and matching pinned windows in both maps.
 * Returns ZX_UNAVAILABLE for unprepared maps or ZX_BUSY during a window
 * lease/video operation. Returns ZX_UNSAFE_CONTEXT for mismatching pinned
 * windows or a zero argument, since disabling the pager overlays all RAM. */
zx_status_t bc_set_page_manager_enabled(uint8_t enabled);
/* Override the pinned-window mask: bits 0..3 represent W0..W3; zero pins none.
 * May be called before or after init. Calling before init disables automatic
 * calculation on the next init; calling after init replaces the mask now.
 * There is no API to clear the override. Supply only bits 0..3; the byte is
 * stored unchanged. Include every window holding resident code, data or stack;
 * the library does not validate the assertion. */
void bc_set_pinned_windows(uint8_t mask);
/* Select the FPGA window-readback port: BD for the standard image, BE for
 * portbemux images. Before init, record the selection for zx_init to check.
 * After init, probe the new port before refreshing the window and video
 * caches. If all probed memory registers read FF, return ZX_UNSAFE_CONTEXT
 * and retain the previous backend and caches. Selecting the current backend
 * is a no-op. Returns ZX_INVALID_ARGUMENT for an unknown backend and ZX_BUSY
 * during a window lease/video operation. */
zx_status_t bc_set_readback_backend(bc_readback_backend_t backend);
/* Set BF.0 shadow-port override (zero off, nonzero on), changing mirrored-port
 * decoding. Returns ZX_BUSY during a video operation, otherwise ZX_OK. */
zx_status_t bc_set_shadow_ports_override(uint8_t enabled);
/* Set write protection to exactly 0 or 1 for a window in the active map,
 * preserving its other settings. Constraints and statuses follow
 * bc_configure_window. */
zx_status_t bc_set_write_protection(zx_window_t window, uint8_t protected);
/* Save the window's active-map configuration and apply temporary settings.
 * Only one lease may be active globally; another acquire returns ZX_BUSY.
 * Requires a known mapping and the same conditions as bc_configure_window.
 * Keep lease at the same CPU-accessible address until release; do not modify
 * its fields or place code, stack, lease or needed data in the remapped window. */
zx_status_t bc_window_acquire(zx_window_t window, bc_window_config_t temporary,
                              bc_window_lease_t *lease);
/* Restore the mapping saved by bc_window_acquire and invalidate the lease on
 * success. NULL/inactive handles return ZX_INVALID_ARGUMENT; a different active
 * handle returns ZX_BUSY. On restoration failure the lease remains active. */
zx_status_t bc_window_release(bc_window_lease_t *lease);

/* Set up a banked heap that grows one physical page at a time from pool.
 * page_storage is caller-owned resident memory with page_capacity entries.
 * Use an unpinned window W1..W3 and call zx_init first. Give each heap its
 * own lease object. Keep the heap, pool, page_storage and lease resident.
 * Requires the classic z88dk named-heap functions. */
zx_status_t bc_ram_heap_init(zx_ram_heap_t *heap, zx_ram_page_pool_t *pool,
                             zx_ram_heap_page_t *page_storage, uint16_t page_capacity,
                             zx_window_t window, bc_window_lease_t *lease);
#endif
