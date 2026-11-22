#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t bc__video_find_page_windows(bc_map_t map, const bc__draw_surface_t *surface,
                                        zx_window_t windows[2]) {
    uint8_t index;

    windows[0] = ZX_WINDOW_0;
    windows[1] = ZX_WINDOW_0;
    for (index = 1; index < 4; ++index) {
        const bc_window_config_t *config = &bc_mem_window_cache[map][index];
        zx_window_t window;

        if (config->kind != BC_RAM || config->substitute_from_7ffd_or_dos ||
            config->write_protected)
            continue;
        window = ZX__WINDOW_ADDRESS(index);
        if (windows[0] == ZX_WINDOW_0 && config->physical_page == surface->page0)
            windows[0] = window;
        if (windows[1] == ZX_WINDOW_0 && config->physical_page == surface->page1)
            windows[1] = window;
    }

    return (windows[0] && windows[1]) ? ZX_OK : ZX_UNAVAILABLE;
}
