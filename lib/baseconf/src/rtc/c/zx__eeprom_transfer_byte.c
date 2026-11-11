#include "../internal.h"

zx_status_t zx__eeprom_transfer_byte(uint16_t offset, uint8_t *byte, uint8_t writing) {
    zx__avr_window_scope_t state;
    zx_status_t status;
    uint8_t caps;

    status = zx__avr_window_begin((zx_avr_window_t)zx__avr_selected_window, &state);
    if (status != ZX_OK) return status;
    caps = state.control & ZX__RTC_CAPS_LED;
    zx__rtc_write_scoped(ZX_RTC_CONTROL_A, (uint8_t)(offset >> 4));
    zx__rtc_write_scoped(ZX_RTC_CONTROL_C, caps | ZX__RTC_EEPROM);
    if (writing)
        zx__rtc_write_scoped((uint8_t)(ZX__RTC_EXTENSION | (offset & 0x0fu)), *byte);
    else
        *byte = zx__rtc_read_scoped((uint8_t)(ZX__RTC_EXTENSION | (offset & 0x0fu)));
    /* Turn off EEPROM selection before restoring the remembered type. */
    zx__rtc_write_scoped(ZX_RTC_CONTROL_C, caps);
    zx__avr_window_end(&state);
    return ZX_OK;
}
