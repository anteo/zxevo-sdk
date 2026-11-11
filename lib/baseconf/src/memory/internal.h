#ifndef BASECONF_MEMORY_INTERNAL_H
#define BASECONF_MEMORY_INTERNAL_H

#include <baseconf.h>
#include "../internal.h"
#include "../../../common/src/memory/internal.h"

#define BC_PORT_BF 0x00bfu

extern bc_readback_backend_t bc_mem_readback_backend;
extern uint8_t bc_mem_maps_prepared;
extern uint8_t bc_mem_pinned_window_mask;
extern uint8_t bc_mem_pinned_window_override;
extern uint8_t bc_mem_active_map;
extern uint8_t bc_mem_initialized;
extern bc_window_config_t bc_mem_window_cache[2][4];
extern bc_window_lease_t *bc_mem_active_window_lease;
uint8_t bc__mem_readback_is_unsafe(bc_readback_backend_t backend) __z88dk_fastcall;
/* Reconstruct the xx77 port from one 0Ch readback byte. */
uint16_t bc__mem_xx77_port(uint8_t config) __z88dk_fastcall;
void bc__mem_decode_window(uint8_t map, uint8_t window, uint8_t config_bits,
                           uint8_t substitute_bits, uint8_t protect_bits, uint8_t page_value);
void bc__mem_refresh_all_windows(void);
uint8_t bc__mem_pinned_maps_match(void);
/* Save BF and temporarily enable shadow I/O. Open accepts a BF byte already
 * read by the caller. End takes the original byte. The caller owns IRQ state. */
uint8_t bc__mem_shadow_scope_begin(void);
void bc__mem_shadow_scope_open(uint8_t saved_bf) __z88dk_fastcall;
void bc__mem_shadow_scope_end(uint8_t saved_bf) __z88dk_fastcall;
void bc__mem_write_shadow_override(uint8_t enabled) __z88dk_fastcall;
zx_status_t bc__mem_write_eff7(uint8_t data);
void bc__mem_apply_window(uint8_t window, const bc_window_config_t *c);
zx_status_t bc_resync(void);
zx_status_t bc_configure_window(bc_map_t map, zx_window_t window,
                                const bc_window_config_t *configuration);
zx_status_t bc_get_window_config(bc_map_t map, zx_window_t window,
                                 bc_window_config_t *configuration);
zx_status_t bc_map_ram_page(zx_window_t window, zx_ram_page_t page);
zx_status_t bc_map_flash_bank(zx_window_t window, bc_flash_bank_t bank);
zx_status_t bc_set_write_protection(zx_window_t window, uint8_t protected);
zx_status_t bc_select_map(bc_map_t map);
zx_status_t bc_select_screen(zx_screen_t screen);
zx_status_t bc_set_addressing(bc_addressing_t addressing);
zx_status_t bc_set_page_manager_enabled(uint8_t enabled);
zx_status_t bc_set_shadow_ports_override(uint8_t enabled);
zx_status_t bc_get_paging_state(bc_paging_snapshot_t *state);
zx_status_t bc_window_acquire(zx_window_t window, bc_window_config_t temporary,
                              bc_window_lease_t *lease);
zx_status_t bc_window_release(bc_window_lease_t *lease);

#endif
