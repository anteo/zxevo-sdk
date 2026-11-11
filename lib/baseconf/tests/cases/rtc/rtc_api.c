#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

static uint8_t bcd_in_range(uint8_t value, uint8_t min, uint8_t max) {
    uint8_t units = value & 15u;
    uint8_t tens = value >> 4;
    uint8_t decimal = 10u * tens + units;
    return units <= 9 && tens <= 9 && decimal >= min && decimal <= max;
}

static void check_clock(void) {
    zx_datetime_t date;
    zx_rtc_control_c_t control;
    uint8_t format, after;
    ZX_ASSERT(zx_rtc_read(ZX_RTC_CONTROL_B, &format) == ZX_OK);
    ZX_ASSERT(zx_rtc_read_datetime(&date, ZX_RTC_BCD) == ZX_OK);
    ZX_ASSERT(bcd_in_range(date.second, 0, 59));
    ZX_ASSERT(bcd_in_range(date.minute, 0, 59));
    ZX_ASSERT(bcd_in_range(date.hour, 0, 23));
    ZX_ASSERT(bcd_in_range(date.weekday, 1, 7));
    ZX_ASSERT(bcd_in_range(date.day, 1, 31));
    ZX_ASSERT(bcd_in_range(date.month, 1, 12));
    ZX_ASSERT(bcd_in_range(date.year, 0, 99));
    ZX_ASSERT(zx_rtc_read(ZX_RTC_CONTROL_B, &after) == ZX_OK && after == format);
    ZX_ASSERT(zx_rtc_control_c_read(&control) == ZX_OK && control.eeprom_window == 0);
    ZX_ASSERT(zx_rtc_write((zx_rtc_index_t)0x10, 0) == ZX_INVALID_ARGUMENT);
    zx_test_step_marker("clock_bcd");
}

static void check_nvram(void) {
    uint8_t old, readback = 0;
    zx_status_t status = zx_nvram_read(0x70, &old);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;

    ZX_ASSERT(zx_nvram_write(0x70, old ^ 0xa5) == ZX_OK);
    status = zx_nvram_read(0x70, &readback);
    ZX_ASSERT(zx_nvram_write(0x70, old) == ZX_OK);
    ZX_ASSERT(status == ZX_OK && readback == (uint8_t)(old ^ 0xa5));
    ZX_ASSERT(zx_nvram_read(0x70, &readback) == ZX_OK && readback == old);
    ZX_ASSERT(zx_nvram_write(0xe7, 0) == ZX_INVALID_ARGUMENT);
    zx_test_step_marker("nvram");
}

static void check_avr(void) {
    zx_avr_version_t version;
    bc_video_output_t output;
    ZX_ASSERT(zx_read_avr_version(ZX_AVR_WINDOW_VERSION, &version) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(zx_avr_window_select(ZX_AVR_WINDOW_MODES) == ZX_OK);
    ZX_ASSERT(zx_read_avr_version(ZX_AVR_WINDOW_VERSION, &version) == ZX_OK);
    ZX_ASSERT(memcmp(version.name, "ZXEvo", 5) == 0);
    ZX_ASSERT(version.year == 2000u + ((version.date >> 9) & 0x3fu));
    ZX_ASSERT(version.month >= 1 && version.month <= 12);
    ZX_ASSERT(version.day >= 1 && version.day <= 31);
    ZX_ASSERT(zx_read_avr_version(ZX_AVR_WINDOW_MODES, &version) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(bc_read_video_output(&output) == ZX_OK);
    ZX_ASSERT(output.raster <= BC_RASTER_128K);
    zx_test_step_marker("avr_metadata");
}

static void check_eeprom_contract(void) {
    const uint16_t last = 4095;
    const uint16_t end = 4096;
    uint8_t bytes[] = {0xa5, 0x5a};
    ZX_ASSERT(bc_eeprom_window_set(1) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(zx_eeprom_read(last, bytes, 1) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(zx_eeprom_write(last, bytes, 1) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(bytes[0] == 0xa5 && bytes[1] == 0x5a);
    ZX_ASSERT(zx_eeprom_read(last, bytes, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_eeprom_write(last, bytes, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_eeprom_read(end, 0, 0) == ZX_OK);
    ZX_ASSERT(zx_eeprom_write(end, 0, 0) == ZX_OK);
    zx_test_step_marker("eeprom_contract");
    zx_test_step_skip("eeprom_pages", "ZEsarUX does not model the 4 KiB EEPROM page selector");
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        check_clock();
        check_nvram();
        check_eeprom_contract();
        check_avr();
    }
    zx_test_finish();
    return 0;
}
