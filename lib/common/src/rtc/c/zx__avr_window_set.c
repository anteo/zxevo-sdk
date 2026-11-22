#include "../internal.h"

zx_status_t zx__avr_window_set(zx_avr_window_t type) {
    zx__avr_window_scope_t scope;
    zx_status_t status = zx__avr_select_window(type, &scope);
    if (status == ZX_OK) zx__avr_restore_mux(&scope);
    return status;
}
