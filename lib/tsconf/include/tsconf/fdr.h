#ifndef TSCONF_FDR_H
#define TSCONF_FDR_H

#include <stdint.h>
#include <zx/status.h>

#define TS_FDR_PRESENT 0x20u

/* These calls require an FDR build. Use TS_FDR_PRESENT in saved Status to
 * check availability. Set capture to 0 or 1. Captured data can be moved
 * to RAM with TS_DMA_FDR_TO_RAM. */
void ts_fdr_set_capture(uint8_t enabled) __z88dk_fastcall;

/* Read the latched 19-bit count, low byte first. Serialize against any
 * other reader of the count registers. Returns ZX_INVALID_ARGUMENT for NULL. */
zx_status_t ts_fdr_read_count(uint32_t *count) __z88dk_fastcall;

#endif
