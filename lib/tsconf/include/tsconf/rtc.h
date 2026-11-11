#ifndef TSCONF_RTC_H
#define TSCONF_RTC_H

#include <zx/rtc.h>

#define TS_RTC_MODIFIERS_EXT ((zx_rtc_index_t)0x0eu)
#define TS_AVR_WINDOW_CONFIG ((zx_avr_window_t)0x0eu)
#define TS_AVR_WINDOW_SPI_FLASH ((zx_avr_window_t)0x10u)

/* Enable or disable GlukClock (EFF7.D7). The register is write-only.
 * Enable it before using zx/rtc.h or the PS/2 APIs, outside DOS/VDOS. */
void ts_rtc_set_enabled(uint8_t enabled) __z88dk_fastcall;

#endif
