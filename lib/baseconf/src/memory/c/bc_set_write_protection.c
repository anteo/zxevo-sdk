#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

zx_status_t bc_set_write_protection(zx_window_t window, uint8_t protected) {
    bc_window_config_t c;
    bc_map_t map;
    zx_status_t status;
    if (window > ZX_WINDOW_3 || protected > 1) return ZX_INVALID_ARGUMENT;
    map = bc_get_active_map();
    status = bc_get_window_config(map, window, &c);
    if (status != ZX_OK) return status;
    c.write_protected = protected;
    return bc_configure_window(map, window, &c);
}
