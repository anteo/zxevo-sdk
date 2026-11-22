#include "../internal.h"

zx_status_t zx__avr_select_window(zx_avr_window_t type, zx__avr_window_scope_t *scope) {
    uint8_t control;

    scope->ports = zx__rtc_scope_begin();
    control = zx__rtc_read_scoped(ZX_RTC_CONTROL_C);
    if (control == 0xffu) {
        zx__rtc_scope_end(scope->ports);
        return ZX_UNAVAILABLE;
    }
    scope->control = control & ZX__RTC_CONTROL_C_WRITABLE;
    scope->previous_type = zx__avr_selected_window;
    /* RTC C bit 0 clears the PS/2 log when written as one. */
    if (control & ZX__RTC_EEPROM)
        zx__rtc_write_scoped(ZX_RTC_CONTROL_C, control & ZX__RTC_CAPS_LED);
    zx__rtc_write_scoped(ZX__RTC_EXTENSION, (uint8_t)type);
    zx__avr_selected_window = (uint8_t)type;
    zx__avr_window_known = 1;
    return ZX_OK;
}
