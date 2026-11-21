#include <baseconf.h>
#include "../internal.h"

zx_status_t bc_window_release(bc_window_lease_t *lease) {
    zx_status_t status;
    if (!lease || !lease->active) return ZX_INVALID_ARGUMENT;
    if (bc_mem_active_window_lease != lease) return ZX_BUSY;
    status = bc__mem_configure_window((bc_map_t)lease->map, lease->window, &lease->previous, 1);
    if (status == ZX_OK) {
        lease->active = 0;
        bc_mem_active_window_lease = 0;
    }
    return status;
}
