#include "../internal.h"

zx_status_t bc_eeprom_window_set(uint8_t enabled) {
    uint16_t scope;
    uint8_t control;
    uint8_t desired;

    if (!zx__avr_window_known) return ZX_UNSAFE_CONTEXT;

    scope = zx__rtc_scope_begin();
    control = zx__rtc_read_scoped(ZX_RTC_CONTROL_C);
    desired = (control & ZX__RTC_CAPS_LED) | (enabled ? ZX__RTC_EEPROM : 0);
    if ((control & ZX__RTC_EEPROM) != (desired & ZX__RTC_EEPROM)) {
        zx__rtc_write_scoped(ZX_RTC_CONTROL_C, desired);
        if (!enabled) zx__rtc_write_scoped(ZX__RTC_EXTENSION, zx__avr_selected_window);
    }
    zx__rtc_scope_end(scope);
    return ZX_OK;
}
