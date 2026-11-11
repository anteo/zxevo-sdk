#include <baseconf.h>

bc_readback_backend_t bc_mem_readback_backend = BC_READBACK_BD;
uint8_t bc_mem_maps_prepared;
uint8_t bc_mem_pinned_window_mask;
uint8_t bc_mem_pinned_window_override;
uint8_t bc_mem_active_map;
uint8_t bc_mem_initialized;
bc_window_config_t bc_mem_window_cache[2][4];
bc_window_lease_t *bc_mem_active_window_lease;
