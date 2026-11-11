#ifndef ZX_TIMING_H
#define ZX_TIMING_H

#include <stdint.h>
#include <zx/status.h>

/* The values match the CPU speed selector in TSConf SysConfig. */
typedef enum { ZX_CPU_3_5_MHZ = 0, ZX_CPU_7_MHZ = 1, ZX_CPU_14_MHZ = 2 } zx_cpu_speed_t;

/* Return the CPU clock selector. BaseConf uses live readback. TSConf uses
 * settings recorded by the SDK and returns ZX_NOT_INITIALIZED until it
 * knows the clock. Leave *speed untouched on error. */
zx_status_t zx_get_cpu_speed(zx_cpu_speed_t *speed) __z88dk_fastcall;
/* Select 3.5, 7 or 14 MHz while preserving the cache policy. Serialize
 * access to the clock and cache registers. BaseConf confirms the clock
 * via readback and can return ZX_UNSAFE_CONTEXT. TSConf returns
 * ZX_NOT_INITIALIZED until the SDK knows the cache mask. */
zx_status_t zx_set_cpu_speed(zx_cpu_speed_t speed) __z88dk_fastcall;

/* Report the nominal frame period in 3.5 MHz T-states, independent of
 * CPU turbo. BaseConf reads the active AVR raster and requires known AVR
 * window ownership. TSConf uses the raster timing configured at build time.
 * Return ZX_INVALID_ARGUMENT for NULL and leave the output untouched on error. */
zx_status_t zx_frame_period(uint32_t *tstates) __z88dk_fastcall;

#endif
