#include <string.h>
#include <zx/ps2.h>
#include <tsconf/rtc.h>
#include <zx_test.h>

#include "../../../src/rtc/internal.h"

/* The indexed AVR protocol is scripted at link time. Real ports and NVRAM
 * are exercised separately, since ZEsarUX does not model a live TSConf RTC
 * or the banked EEPROM. */
static uint8_t clock_registers[10] = {0, 0, 0, 0, 0x12, 0, 6, 0x14, 0x11, 0x26};
static const uint8_t rollover[] = {0x59, 0, 0, 0};
static const uint8_t unstable[] = {1, 2, 3, 4, 5, 6};
static const uint8_t *seconds;
static uint8_t sample_count, sample_index;
static uint8_t format_register = 2;
static uint8_t bank = 0x7f, control = 0x93, extension = 3, scancode = 0x1c;
static uint8_t modifiers_lo = ZX_PS2_LCTRL | ZX_PS2_RSHIFT;
static uint8_t modifiers_hi = (ZX_PS2_LWIN | ZX_PS2_MENU) >> 8;
static uint8_t eeprom[32];
static uint8_t eeprom_last;
static uint8_t log_clears, unexpected_writes;
static const uint8_t application[16] = {'Z', 'X', 'E', 'v', 'o',  ' ',  'T',  'S',
                                        'C', 'o', 'n', 'f', 0x6a, 0xb5, 0x34, 0x12};
static const uint8_t bootloader[16] = {'B', 'o', 'o', 't', 'l',  'o',  'a',  'd',
                                       'e', 'r', ' ', ' ', 0x6a, 0x35, 0x78, 0x56};

uint8_t zx__rtc_read_scoped(uint8_t index) __z88dk_fastcall {
    if (index == ZX_RTC_SECONDS && sample_index < sample_count) return seconds[sample_index++];
    if (index == ZX_RTC_MINUTES && seconds == rollover && sample_index == 1u)
        return 0x59;                /* from the rejected sample */
    if (index < sizeof(clock_registers)) return clock_registers[index];
    if (index == ZX_RTC_CONTROL_A) return bank;
    if (index == ZX_RTC_CONTROL_B) return format_register;
    if (index == ZX_RTC_CONTROL_C) {
        uint8_t value = control;
        control &= (uint8_t)~0x10u;
        return value;
    }
    if (index == ZX_RTC_MODIFIERS) return modifiers_lo;
    if (index == TS_RTC_MODIFIERS_EXT) return modifiers_hi;
    if (index >= 0xf0u && (control & 0x80u)) {
        if (bank == 0xffu && index == 0xffu) return eeprom_last;
        ZX_ASSERT(bank < 2);
        return bank < 2 ? eeprom[(bank << 4) | (index & 15u)] : 0xff;
    }
    if (index >= 0xf0u) {
        if (extension == ZX_AVR_WINDOW_VERSION) return application[index & 15u];
        if (extension == ZX_AVR_WINDOW_BOOTLOADER) return bootloader[index & 15u];
        if (extension == ZX_AVR_WINDOW_PS2_LOG) {
            uint8_t value = scancode;
            scancode = 0;
            return value;
        }
    }
    return 0xffu;
}

void zx__rtc_write_scoped(uint8_t index, uint8_t value) {
    if (index == ZX_RTC_CONTROL_A) {
        bank = value;
    } else if (index == ZX_RTC_CONTROL_C) {
        control = (control & (uint8_t)~0x82u) | (value & 0x82u);
        if (value & 1u) {
            ++log_clears;
            scancode = 0;
        }
    } else if (index >= 0xf0u && (control & 0x80u)) {
        if (bank == 0xffu && index == 0xffu) {
            eeprom_last = value;
        } else {
            ZX_ASSERT(bank < 2);
            if (bank < 2) eeprom[(bank << 4) | (index & 15u)] = value;
        }
    } else if (index == 0xf0u) {
        extension = value;
    } else {
        ++unexpected_writes;
    }
}

static void check_clock(void) {
    zx_datetime_t date;
    zx_datetime_t unchanged;

    ZX_ASSERT(zx_rtc_read_datetime(0, ZX_RTC_BINARY) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_rtc_read_datetime(&date, (zx_rtc_format_t)2) == ZX_INVALID_ARGUMENT);
    seconds = rollover;
    sample_count = sizeof(rollover);
    ZX_ASSERT(zx_rtc_read_datetime(&date, ZX_RTC_BINARY) == ZX_OK);
    ZX_ASSERT(sample_index == 4u && date.second == 0 && date.minute == 0 && date.hour == 12);
    ZX_ASSERT(date.weekday == 6 && date.day == 14 && date.month == 11 && date.year == 26);
    ZX_ASSERT(format_register == 2 && unexpected_writes == 0);

    format_register = 6;
    clock_registers[ZX_RTC_SECONDS] = 58;
    clock_registers[ZX_RTC_MINUTES] = 34;
    clock_registers[ZX_RTC_HOURS] = 23;
    clock_registers[ZX_RTC_DAY] = 14;
    clock_registers[ZX_RTC_MONTH] = 11;
    clock_registers[ZX_RTC_YEAR] = 26;
    ZX_ASSERT(zx_rtc_read_datetime(&date, ZX_RTC_BCD) == ZX_OK);
    ZX_ASSERT(date.second == 0x58 && date.minute == 0x34 && date.hour == 0x23);
    ZX_ASSERT(date.day == 0x14 && date.month == 0x11 && date.year == 0x26);
    ZX_ASSERT(format_register == 6 && unexpected_writes == 0);

    unchanged = date;
    seconds = unstable;
    sample_count = sizeof(unstable);
    sample_index = 0;
    ZX_ASSERT(zx_rtc_read_datetime(&date, ZX_RTC_BINARY) == ZX_TIMEOUT);
    ZX_ASSERT(sample_index == 6 && !memcmp(&date, &unchanged, sizeof(date)));
    format_register = 0xff;
    ZX_ASSERT(zx_rtc_read_datetime(&date, ZX_RTC_BINARY) == ZX_UNAVAILABLE);
    ZX_ASSERT(!memcmp(&date, &unchanged, sizeof(date)));
    zx_test_step_marker("stable-clock");
}

static void check_versions(void) {
    zx_avr_version_t version;

    ZX_ASSERT(zx_read_avr_version(ZX_AVR_WINDOW_VERSION, &version) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(zx_avr_window_select(ZX_AVR_WINDOW_MODES) == ZX_OK);
    ZX_ASSERT(extension == ZX_AVR_WINDOW_MODES && control == 0x83 && !log_clears);
    ZX_ASSERT(zx_read_avr_version(ZX_AVR_WINDOW_VERSION, &version) == ZX_OK);
    ZX_ASSERT(!memcmp(version.name, application, sizeof(version.name)));
    ZX_ASSERT(version.date == 0xb56a && version.year == 2026 && version.month == 11 &&
              version.day == 10 && version.official && version.crc == 0x1234);
    ZX_ASSERT(zx_read_avr_version(ZX_AVR_WINDOW_BOOTLOADER, &version) == ZX_OK);
    ZX_ASSERT(!memcmp(version.name, bootloader, sizeof(version.name)));
    ZX_ASSERT(version.date == 0x356a && !version.official && version.crc == 0x5678);
    ZX_ASSERT(extension == ZX_AVR_WINDOW_MODES && control == 0x83 && !log_clears);
    zx_test_step_marker("avr-metadata");
}

static void check_eeprom(void) {
    const uint8_t input[] = {0x12, 0x34, 0x56};
    uint8_t output[sizeof(input)];

    ZX_ASSERT(zx_eeprom_write(4095, input, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_eeprom_read(65535u, output, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_eeprom_read(4096, 0, 0) == ZX_OK);
    ZX_ASSERT(zx_eeprom_write(14, input, sizeof(input)) == ZX_OK);
    ZX_ASSERT(bank == 0x7f && extension == ZX_AVR_WINDOW_MODES && control == 0x83);
    ZX_ASSERT(eeprom[14] == 0x12 && eeprom[15] == 0x34 && eeprom[16] == 0x56);
    control = 0x03;
    ZX_ASSERT(zx_eeprom_read(14, output, sizeof(output)) == ZX_OK);
    ZX_ASSERT(!memcmp(output, input, sizeof(output)));
    ZX_ASSERT(zx_eeprom_write(4095, input, 1) == ZX_OK);
    ZX_ASSERT(zx_eeprom_read(4095, output, 1) == ZX_OK && output[0] == 0x12);
    ZX_ASSERT(bank == 0x7f && extension == ZX_AVR_WINDOW_MODES && control == 0x03 && !log_clears);
    zx_test_step_marker("eeprom-bank-boundary");
}

static void check_ps2(void) {
    uint16_t modifiers;
    uint8_t code;

    ZX_ASSERT(zx_ps2_modifiers(&modifiers) == ZX_OK);
    ZX_ASSERT(modifiers == (ZX_PS2_LCTRL | ZX_PS2_RSHIFT | ZX_PS2_LWIN | ZX_PS2_MENU));
    modifiers_lo = ZX_PS2_LALT | 0x80u;
    modifiers_hi = 0xffu;          /* 0Eh is arbitrary NVRAM in single-mask mode. */
    ZX_ASSERT(zx_ps2_modifiers(&modifiers) == ZX_OK && modifiers == ZX_PS2_LALT);
    modifiers_lo = 0xffu;
    ZX_ASSERT(zx_ps2_modifiers(&modifiers) == ZX_UNAVAILABLE && modifiers == ZX_PS2_LALT);
    ZX_ASSERT(zx_ps2_scancode_read(&code) == ZX_OK && code == 0x1c);
    ZX_ASSERT(zx_ps2_scancode_read(&code) == ZX_OK && code == ZX_PS2_SCANCODE_EMPTY);
    scancode = ZX_PS2_SCANCODE_OVERFLOW;
    ZX_ASSERT(zx_ps2_scancode_read(&code) == ZX_OK && code == ZX_PS2_SCANCODE_OVERFLOW);
    scancode = 0xf0;
    control = 0x93;
    ZX_ASSERT(zx_ps2_log_clear() == ZX_OK && log_clears == 1 && control == 0x83);
    ZX_ASSERT(zx_ps2_scancode_read(&code) == ZX_OK && code == ZX_PS2_SCANCODE_EMPTY);
    ZX_ASSERT(extension == ZX_AVR_WINDOW_MODES && control == 0x83);
    zx_test_step_marker("ps2-modifiers-and-log");
}

static void check_control(void) {
    zx_rtc_control_c_t state;

    control = 0x9du;
    ZX_ASSERT(zx_rtc_control_c_read(&state) == ZX_OK);
    ZX_ASSERT(!state.caps_led && state.num_led && state.sd_present && state.sd_writable &&
              state.time_updated && state.eeprom_window);
    ZX_ASSERT(control == 0x8du);
    ZX_ASSERT(zx_caps_led_set(1) == ZX_OK && control == 0x8fu);
    ZX_ASSERT(zx_caps_led_set(0) == ZX_OK && control == 0x8du);
    ZX_ASSERT(log_clears == 1 && extension == ZX_AVR_WINDOW_MODES);
    zx_test_step_marker("rtc-control-c");
}

int main(void) {
    zx_test_init();
    check_clock();
    check_versions();
    check_eeprom();
    check_ps2();
    check_control();
    zx_test_finish();
    return 0;
}
