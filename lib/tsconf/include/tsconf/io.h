#ifndef TSCONF_IO_H
#define TSCONF_IO_H

#include <stdint.h>

#define TS_STATUS_COLD_BOOT 0x40u

#define TS_IRQ_FRAME 0x01u
#define TS_IRQ_LINE 0x02u
#define TS_IRQ_DMA 0x04u
#define TS_IRQ_AVR 0x08u
#define TS_IRQ_COPPER 0x10u

/* Reading Status clears the cold-boot and optional Copper-ready latches. */
uint8_t ts_io_read_status(void);

/* Write SysConfig. Bits 1:0 select 3.5, 7 or 14 MHz (0, 1 or 2).
 * Bit 2 sets the cache enable for all four windows. The SDK records both
 * settings for zx_get_cpu_speed and zx_set_cpu_speed. Route register
 * writes through the SDK when using those calls. */
void ts_io_set_system_config(uint8_t config) __z88dk_fastcall;

/* Write INTMask. Bits 0..3 enable frame, line/FT812, DMA and AVR IRQs,
 * respectively. Bit 4 enables Copper IRQs on builds with Copper. */
void ts_io_set_interrupt_mask(uint8_t mask) __z88dk_fastcall;

#endif
