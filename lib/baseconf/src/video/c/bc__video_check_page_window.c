#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t bc__video_check_page_window(bc_map_t map, zx_window_t window, zx_ram_page_t page) {
    const bc_window_config_t *config;

    if (window == ZX_WINDOW_0 || !ZX__WINDOW_VALID(window)) return ZX_INVALID_ARGUMENT;
    config = &bc_mem_window_cache[map][ZX__WINDOW_INDEX(window)];
    if (config->kind != BC_RAM || config->substitute_from_7ffd_or_dos || config->write_protected ||
        config->physical_page != page)
        return ZX_UNAVAILABLE;
    return ZX_OK;
}
