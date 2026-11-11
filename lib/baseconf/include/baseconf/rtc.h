#ifndef BASECONF_RTC_H
#define BASECONF_RTC_H

#include <stdint.h>
#include <zx/rtc.h>
#include <baseconf.h>

typedef enum {
    BC_RASTER_PENTAGON = 0,
    BC_RASTER_60HZ = 1,
    BC_RASTER_48K = 2,
    BC_RASTER_128K = 3
} bc_raster_code_t;

typedef struct {
    bc_raster_code_t raster;
    uint8_t vga;
    uint8_t tape_out;
    uint8_t caps_led;
} bc_video_output_t;

/* Enable (nonzero) or disable (zero) the global AVR EEPROM window, preserving
 * the remembered extension type and Caps LED. Reads control C, clearing
 * time_updated. Returns ZX_UNSAFE_CONTEXT until zx_avr_window_select is called. */
zx_status_t bc_eeprom_window_set(uint8_t enabled);
/* Read current raster, VGA, tape-output and Caps LED state through extension
 * type 3; restore the previous extension/EEPROM selection. Requires known
 * ownership; returns ZX_UNSAFE_CONTEXT if unknown, ZX_INVALID_ARGUMENT for NULL. */
zx_status_t bc_read_video_output(bc_video_output_t *output);

#endif
