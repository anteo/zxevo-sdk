#include "../internal.h"

zx_status_t bc_configure_window(bc_map_t map, zx_window_t window,
                                const bc_window_config_t *configuration) {
    return bc__mem_configure_window(map, window, configuration, 0);
}
