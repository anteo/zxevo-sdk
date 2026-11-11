#include "../internal.h"

#define RTC_CONTROL_NUM_LED 0x01u
#define RTC_CONTROL_SD_WRITABLE 0x04u
#define RTC_CONTROL_SD_PRESENT 0x08u
#define RTC_CONTROL_TIME_UPDATED 0x10u

zx_status_t zx_rtc_control_c_read(zx_rtc_control_c_t *state) {
    uint8_t value;
    zx_status_t status;
    if (!state) return ZX_INVALID_ARGUMENT;
    status = zx_rtc_read(ZX_RTC_CONTROL_C, &value);
    if (status != ZX_OK) return status;
    if (value == 0xffu) return ZX_UNAVAILABLE;
    state->caps_led = (uint8_t)((value & ZX__RTC_CAPS_LED) != 0);
    state->num_led = (uint8_t)((value & RTC_CONTROL_NUM_LED) != 0);
    state->sd_writable = (uint8_t)((value & RTC_CONTROL_SD_WRITABLE) != 0);
    state->sd_present = (uint8_t)((value & RTC_CONTROL_SD_PRESENT) != 0);
    state->time_updated = (uint8_t)((value & RTC_CONTROL_TIME_UPDATED) != 0);
    state->eeprom_window = (uint8_t)((value & ZX__RTC_EEPROM) != 0);
    return ZX_OK;
}
