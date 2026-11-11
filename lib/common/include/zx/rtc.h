#ifndef ZX_RTC_H
#define ZX_RTC_H

#include <stdint.h>
#include <zx/status.h>

typedef enum { ZX_RTC_BINARY, ZX_RTC_BCD } zx_rtc_format_t;

typedef enum {
    ZX_RTC_SECONDS = 0x00,
    ZX_RTC_MINUTES = 0x02,
    ZX_RTC_HOURS = 0x04,
    ZX_RTC_WEEKDAY = 0x06,
    ZX_RTC_DAY = 0x07,
    ZX_RTC_MONTH = 0x08,
    ZX_RTC_YEAR = 0x09,
    ZX_RTC_CONTROL_A = 0x0a,
    ZX_RTC_CONTROL_B = 0x0b,
    ZX_RTC_CONTROL_C = 0x0c,
    ZX_RTC_MODIFIERS = 0x0d
} zx_rtc_index_t;

typedef enum {
    ZX_AVR_WINDOW_VERSION = 0,
    ZX_AVR_WINDOW_BOOTLOADER = 1,
    ZX_AVR_WINDOW_PS2_LOG = 2,
    ZX_AVR_WINDOW_MODES = 3
} zx_avr_window_t;

/* All fields use the selected format. Year is the two-digit RTC year. */
typedef struct {
    uint8_t second, minute, hour, weekday, day, month, year;
} zx_datetime_t;

typedef struct {
    char name[12];    /* Fixed-width firmware name, which may lack a NUL. */
    uint16_t date;   /* Packed build date, including the official bit. */
    uint16_t crc;
    uint16_t year;   /* Full calendar year, 2000..2063. */
    uint8_t official, month, day;
} zx_avr_version_t;

typedef struct {
    uint8_t caps_led, num_led, sd_present, sd_writable, time_updated, eeprom_window;
} zx_rtc_control_c_t;

/* Serialize indexed RTC access with ROM, ISR and NMI users. On TSConf,
 * enable GlukClock with ts_rtc_set_enabled and stay outside DOS/VDOS.
 * BaseConf opens and restores shadow ports as needed. */

/* Read or write a raw byte. BaseConf accepts 00h..0Fh in both directions.
 * TSConf accepts 00h..0Eh for reads and 00h..0Ch for writes. Invalid indices
 * or a NULL read output give ZX_INVALID_ARGUMENT. Hardware defines writable
 * bits and side effects, including acknowledgment on reading control C. */
zx_status_t zx_rtc_read(zx_rtc_index_t index, uint8_t *value);
zx_status_t zx_rtc_write(zx_rtc_index_t index, uint8_t value);

/* Sample date/time, retrying if seconds change. Convert in software
 * without changing control B. Return ZX_TIMEOUT for unstable time,
 * ZX_UNAVAILABLE on floating bus or ZX_INVALID_ARGUMENT for invalid input.
 * Leave the output untouched on failure. */
zx_status_t zx_rtc_read_datetime(zx_datetime_t *datetime, zx_rtc_format_t format);
/* Decode control C, acknowledging the update flag. A floating bus returns
 * ZX_UNAVAILABLE and leaves the output untouched. */
zx_status_t zx_rtc_control_c_read(zx_rtc_control_c_t *state);
/* Set the Caps Lock LED, preserving the EEPROM mux and the PS/2 log.
 * Reading control C acknowledges the update flag. Return ZX_UNAVAILABLE
 * on floating bus. */
zx_status_t zx_caps_led_set(uint8_t enabled);

/* Access caller-owned battery-backed RTC RAM. BaseConf accepts 0Eh..EFh
 * for reads and 0Eh..E6h for writes. TSConf accepts 0Fh..EFh for both.
 * Avoid firmware-owned settings. */
zx_status_t zx_nvram_read(uint8_t index, uint8_t *value);
zx_status_t zx_nvram_write(uint8_t index, uint8_t value);

/* Select and remember an AVR extension. Preserve the EEPROM mux and Caps
 * LED. Call again after an external selector write, since there is no
 * readback. Reading control C acknowledges the clock update flag. */
zx_status_t zx_avr_window_select(zx_avr_window_t type);
/* Read VERSION or BOOTLOADER metadata, restoring the previous extension
 * and EEPROM mux. Establish ownership with zx_avr_window_select first,
 * or the call returns ZX_UNSAFE_CONTEXT. */
zx_status_t zx_read_avr_version(zx_avr_window_t type, zx_avr_version_t *version);

/* Transfer up to 255 bytes in the AVR's 4 KiB EEPROM. Zero length is a
 * no-op for offsets 0..4096, including with a NULL buffer. The mux and
 * extension are preserved; TSConf also restores the bank. BaseConf requires
 * a known AVR extension for nonempty transfers. Each byte acknowledges the
 * clock update flag. A write may be partially committed on error. */
zx_status_t zx_eeprom_read(uint16_t offset, uint8_t *buffer, uint8_t length);
zx_status_t zx_eeprom_write(uint16_t offset, const uint8_t *buffer, uint8_t length);

#endif
