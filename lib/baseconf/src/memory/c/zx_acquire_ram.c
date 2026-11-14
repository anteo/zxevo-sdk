#include <baseconf.h>

typedef char zx__bc_lease_fits[(sizeof(bc_window_lease_t) <= sizeof(zx_ram_lease_t)) ? 1 : -1];

zx_status_t zx_acquire_ram(zx_window_t window, zx_ram_page_t page, zx_ram_lease_t *lease) {
    bc_window_config_t mapping = {BC_RAM, page, 0, 0};
    return bc_window_acquire(window, mapping, (bc_window_lease_t *)lease);
}
