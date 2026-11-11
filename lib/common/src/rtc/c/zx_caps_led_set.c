#include "../internal.h"

zx_status_t zx_caps_led_set(uint8_t enabled) {
    uint16_t scope = zx__rtc_scope_begin();
    uint8_t control = zx__rtc_read_scoped(ZX_RTC_CONTROL_C);
    if (control != 0xffu) {
        uint8_t desired = (control & ZX__RTC_EEPROM) | (enabled ? ZX__RTC_CAPS_LED : 0);
        if ((control & ZX__RTC_CONTROL_C_WRITABLE) != desired)
            zx__rtc_write_scoped(ZX_RTC_CONTROL_C, desired);
    }
    zx__rtc_scope_end(scope);
    return control == 0xffu ? ZX_UNAVAILABLE : ZX_OK;
}
