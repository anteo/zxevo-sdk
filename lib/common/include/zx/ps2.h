#ifndef ZX_PS2_H
#define ZX_PS2_H

#include <stdint.h>
#include <zx/status.h>

#define ZX_PS2_SCANCODE_EMPTY 0x00u
#define ZX_PS2_SCANCODE_OVERFLOW 0xffu

typedef enum {
    ZX_PS2_LCTRL = 0x001,
    ZX_PS2_RCTRL = 0x002,
    ZX_PS2_LALT = 0x004,
    ZX_PS2_RALT = 0x008,
    ZX_PS2_LSHIFT = 0x010,
    ZX_PS2_RSHIFT = 0x020,
    ZX_PS2_F12 = 0x040,
    ZX_PS2_LWIN = 0x100,
    ZX_PS2_RWIN = 0x200,
    ZX_PS2_MENU = 0x400
} zx_ps2_modifier_t;

/* Follow the RTC access requirements in zx/rtc.h. The output pointers must
 * be non-NULL. Output values change only on success. */

/* Read the pressed physical modifiers. BaseConf and single-mask TSConf
 * firmware return a zero high byte. BaseConf returns ZX_UNSUPPORTED if
 * the firmware does not provide the modifier marker. An unavailable AVR
 * returns ZX_UNAVAILABLE. */
zx_status_t zx_ps2_modifiers(uint16_t *modifiers);
/* Pop one raw log byte, including the EMPTY and OVERFLOW markers.
 * Establish AVR window ownership with zx_avr_window_select first, or
 * the call returns ZX_UNSAFE_CONTEXT. The previous window and mux are
 * restored on success. */
zx_status_t zx_ps2_scancode_read(uint8_t *code);
/* Clear the log, preserving the EEPROM mux and Caps LED. Reading RTC C
 * acknowledges the clock update flag. An unavailable AVR returns
 * ZX_UNAVAILABLE. */
zx_status_t zx_ps2_log_clear(void);

#endif
