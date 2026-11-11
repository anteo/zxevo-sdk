#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

zx_status_t bc_window_acquire(zx_window_t window, bc_window_config_t temporary,
                              bc_window_lease_t *lease) {
    bc_map_t map;
    zx_status_t status;
    if (!lease || window > ZX_WINDOW_3) return ZX_INVALID_ARGUMENT;
    if (bc_mem_active_window_lease) return ZX_BUSY;
    map = bc_get_active_map();
    status = bc_get_window_config(map, window, &lease->previous);
    if (status != ZX_OK) return status;
    lease->window = window;
    lease->map = map;
    lease->active = 0;
    status = bc_configure_window(map, window, &temporary);
    if (status != ZX_OK) return status;
    lease->active = 1;
    bc_mem_active_window_lease = lease;
    return ZX_OK;
}
