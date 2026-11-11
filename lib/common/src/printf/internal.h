#ifndef ZX_PRINTF_INTERNAL_H
#define ZX_PRINTF_INTERNAL_H

#include <stdint.h>

/* Platform archive entry point. Consume 1..limit bytes or return -1.
 * For multi-byte runs, stop before NUL or the delimiter. A single byte,
 * including NUL from %c, is always eligible. */
int zx__printf_write(const char *text, uint8_t limit, uint8_t stop);

/* Write the digits backwards from end into a five-byte buffer. */
uint8_t zx__printf_unsigned_string(uint16_t value, uint8_t radix, uint8_t upper, char *end);

#endif
