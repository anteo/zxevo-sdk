#ifndef ZX_FDD_INTERNAL_H
#define ZX_FDD_INTERNAL_H

#include <zx/fdd.h>

/* Return the encoded five-bit system latch, or FFh for invalid input. */
uint8_t zx__fdd_system_byte(const zx_fdd_system_t *cfg) __z88dk_fastcall;

#endif
