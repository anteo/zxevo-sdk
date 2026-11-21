#include <baseconf.h>
#include "../internal.h"

zx_status_t zx_acquired_ram_set_page(zx_ram_lease_t *lease, zx_ram_page_t page) {
    bc_window_lease_t *native = (bc_window_lease_t *)lease;
    bc_window_config_t mapping = {BC_RAM, page, 0, 0};
    if (!lease || !native->active) return ZX_INVALID_ARGUMENT;
    if (bc_mem_active_window_lease != native) return ZX_BUSY;
    return bc__mem_configure_window((bc_map_t)native->map, native->window, &mapping, 1);
}
