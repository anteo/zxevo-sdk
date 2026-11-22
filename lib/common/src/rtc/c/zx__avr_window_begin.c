#include "../internal.h"

zx_status_t zx__avr_window_begin(zx_avr_window_t type, zx__avr_window_scope_t *scope) {
    if (!zx__avr_window_known) return ZX_UNSAFE_CONTEXT;
    return zx__avr_select_window(type, scope);
}
