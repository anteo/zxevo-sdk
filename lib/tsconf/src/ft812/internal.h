#ifndef TSCONF_FT812_INTERNAL_H
#define TSCONF_FT812_INTERNAL_H

#include <tsconf/ft812.h>
#include "../spi/internal.h"

#define TS__FT812_WRITE 0x80u

/* Validate the span and send its address header if it is nonempty. */
zx_status_t ts__ft812_begin(uint32_t address, uint16_t length, uint8_t flag);

#endif
