#include "../internal.h"

void zx__avr_restore_mux(const zx__avr_window_scope_t *scope) {
    if (scope->control & ZX__RTC_EEPROM) zx__rtc_write_scoped(ZX_RTC_CONTROL_C, scope->control);
    zx__rtc_scope_end(scope->ports);
}
