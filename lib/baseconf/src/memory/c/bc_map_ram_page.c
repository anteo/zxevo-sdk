#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

zx_status_t bc_map_ram_page(zx_window_t window, zx_ram_page_t page) {
    bc_window_config_t c;
    if (window > ZX_WINDOW_3) return ZX_INVALID_ARGUMENT;
    c.kind = BC_RAM;
    c.physical_page = page;
    c.substitute_from_7ffd_or_dos = 0;
    c.write_protected = 0;
    return bc_configure_window(bc_get_active_map(), window, &c);
}
