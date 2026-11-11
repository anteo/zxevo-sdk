#ifndef TSCONF_TIMING_H
#define TSCONF_TIMING_H

#include <stdint.h>
#include <zx/status.h>
#include <zx/timing.h>

/* Set the CPU speed and enable caching in all windows for nonzero
 * cache_enabled, or disable it in all windows for zero. This replaces any
 * per-window cache settings. Use ts_memory_set_cache afterward for a mixed
 * mask. Returns ZX_INVALID_ARGUMENT for an invalid speed, otherwise ZX_OK
 * after writing SysConfig. */
zx_status_t ts_set_cpu_speed_and_cache(zx_cpu_speed_t speed, uint8_t cache_enabled);

/* Set the frame IRQ position. horizontal is HSINT in pairs of raster dots
 * (0..223), line is zero-based within the configured frame and line_step is
 * 0..15. The FPGA wraps a nonzero increment at 320 lines, so the 60 Hz
 * profile accepts only zero. Program the compare with frame IRQ disabled.
 * Returns ZX_INVALID_ARGUMENT for out-of-range inputs, ZX_UNSUPPORTED for
 * a nonzero step in the 60 Hz profile, or ZX_OK. */
zx_status_t ts_irq_set_frame_position(uint8_t horizontal, uint16_t line, uint8_t line_step);

#endif
