#include <baseconf.h>

zx_status_t zx_release_ram(zx_ram_lease_t *lease) {
    return bc_window_release((bc_window_lease_t *)lease);
}
