#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

zx_status_t bc_get_window_config(bc_map_t map, zx_window_t window,
                                 bc_window_config_t *configuration) {
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (map > BC_MAP_1 || !ZX__WINDOW_VALID(window) || !configuration) return ZX_INVALID_ARGUMENT;
    *configuration = bc_mem_window_cache[map][ZX__WINDOW_INDEX(window)];
    return ZX_OK;
}
