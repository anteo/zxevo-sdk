#ifndef TSCONF_COPPER_H
#define TSCONF_COPPER_H

#include <stdint.h>
#include <zx/status.h>

#define TS_COPPER_READY 0x80u
#define TS_COPPER_SIGNAL_IRQ 0x01u
#define TS_COPPER_SIGNAL_READY 0x02u
#define TS_COPPER_WRITE(reg_, value_) (((uint16_t)(reg_) << 8) | (uint8_t)(value_))
#define TS_COPPER_SIGNAL(flags_) (0xf500u | ((flags_) & 3u))
#define TS_COPPER_WAIT_X(x_) (0xf700u | (uint8_t)(x_))
#define TS_COPPER_WAIT_Y(y_) (0xfa00u | ((y_) & 0x01ffu))
#define TS_COPPER_JUMP(address_) (0xff00u | (uint8_t)(address_))
#define TS_COPPER_RETURN 0xffffu

/* Copper APIs require a build with COPPER. Stop the sequencer before
 * replacing its list and serialize uploads with all FMAPS/DMA writers.
 * fmaps_base is the enabled 4 KiB-aligned aperture. Upload count words at
 * first_word, up to the end of the 256-word list. A zero count is valid. */
zx_status_t ts_copper_upload(uint16_t fmaps_base, uint8_t first_word, const uint16_t *words,
                             uint16_t count);

/* Start at word 0..254. FFh is reserved for stop and returns invalid argument. */
zx_status_t ts_copper_start(uint8_t first_word) __z88dk_fastcall;
void ts_copper_stop(void);

#endif
