#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

zx_status_t bc_map_flash_bank(zx_window_t window, bc_flash_bank_t bank) {
    bc_window_config_t c;
    if (window > ZX_WINDOW_3 || bank > 31) return ZX_INVALID_ARGUMENT;
    c.kind = BC_FLASH;
    c.physical_page = bank;
    c.substitute_from_7ffd_or_dos = 0;
    c.write_protected = 1;
    return bc_configure_window(bc_get_active_map(), window, &c);
}
