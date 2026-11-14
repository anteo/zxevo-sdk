#include <tsconf.h>

typedef char zx__ts_lease_fits[(sizeof(ts_window_lease_t) <= sizeof(zx_ram_lease_t)) ? 1 : -1];

zx_status_t zx_acquire_ram(zx_window_t window, zx_ram_page_t page, zx_ram_lease_t *lease) {
    return ts_window_acquire(window, page, (ts_window_lease_t *)lease);
}
