#ifndef ZX_BASIC48_H
#define ZX_BASIC48_H

#include <stdint.h>
#include <zx/status.h>

/* Wait for count ticks of the BASIC 48 frame interrupt. Keep BASIC's ROM and
 * workspace mapped and INT enabled while waiting. Zero count returns ZX_OK. */
zx_status_t zx_basic48_wait_frames(uint16_t count) __z88dk_fastcall;

/* Return BASIC's saved border color (0..7) with its workspace mapped. */
uint8_t zx_basic48_get_border_color(void);

#endif
