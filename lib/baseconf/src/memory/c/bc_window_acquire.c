#include <baseconf.h>
#include "../internal.h"

zx_status_t bc_window_acquire(zx_window_t window, bc_window_config_t temporary,
                              bc_window_lease_t *lease) {
    bc_map_t map;
    zx_status_t status;
    if (!lease || !ZX__WINDOW_VALID(window)) return ZX_INVALID_ARGUMENT;
    if (bc_mem_active_window_lease) return ZX_BUSY;
    map = bc_get_active_map();
    status = bc_get_window_config(map, window, &lease->previous);
    if (status != ZX_OK) return status;
    lease->window = window;
    lease->map = map;
    lease->active = 0;
    bc_mem_active_window_lease = lease;
    status = bc__mem_configure_window(map, window, &temporary, 1);
    if (status != ZX_OK) {
        bc_mem_active_window_lease = 0;
        return status;
    }
    lease->active = 1;
    return ZX_OK;
}
