#include <tsconf.h>

zx_status_t zx_release_ram(zx_ram_lease_t *lease) {
    return ts_window_release((ts_window_lease_t *)lease);
}
