#include "../internal.h"

void zx__avr_window_end(const zx__avr_window_scope_t *scope) {
    zx__rtc_write_scoped(ZX__RTC_EXTENSION, scope->previous_type);
    zx__avr_selected_window = scope->previous_type;
    zx__avr_restore_mux(scope);
}
