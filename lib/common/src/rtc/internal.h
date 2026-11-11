#ifndef ZX_RTC_INTERNAL_H
#define ZX_RTC_INTERNAL_H

#include <zx/rtc.h>

#define ZX__RTC_BINARY 0x04u
#define ZX__RTC_CAPS_LED 0x02u
#define ZX__RTC_EEPROM 0x80u
#define ZX__RTC_CONTROL_C_WRITABLE (ZX__RTC_CAPS_LED | ZX__RTC_EEPROM)
#define ZX__RTC_EXTENSION 0xf0u

/* The platform scope serializes indexed access with INT handlers. End
 * restores the entry state saved in the opaque word. */
uint16_t zx__rtc_scope_begin(void);
void zx__rtc_scope_end(uint16_t state) __z88dk_fastcall;
uint8_t zx__rtc_read_scoped(uint8_t index) __z88dk_fastcall;
void zx__rtc_write_scoped(uint8_t index, uint8_t value);

/* The AVR extension selector is write-only. Ownership starts unknown in BSS. */
extern uint8_t zx__avr_selected_window;
extern uint8_t zx__avr_window_known;
typedef struct {
    uint16_t ports;
    uint8_t control;
    uint8_t previous_type;
} zx__avr_window_scope_t;

/* Set a platform-validated extension. */
zx_status_t zx__avr_window_set(zx_avr_window_t type);
/* On success the caller holds the RTC scope until the matching end call. */
zx_status_t zx__avr_window_begin(zx_avr_window_t type, zx__avr_window_scope_t *scope);
void zx__avr_window_end(const zx__avr_window_scope_t *scope);

/* Decode a complete firmware record into a distinct writable output. */
void zx__avr_decode_version(const uint8_t bytes[16], zx_avr_version_t *version);

/* Platform backend. The common caller has validated the offset and byte. */
zx_status_t zx__eeprom_transfer_byte(uint16_t offset, uint8_t *byte, uint8_t writing);

#endif
