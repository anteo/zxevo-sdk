#ifndef ZX_PRINTF_H
#define ZX_PRINTF_H

#include <stdarg.h>

/* Format to the linked platform console, with its controls and wrapping.
 * Uses the console text background. Output does not scroll.
 * Supports %c, %s, %d, %i, %u, %x, %X and %%, optional '-' then '0', and a
 * decimal field width (clamped to 255). Integers are 16-bit; precision, length
 * modifiers and floating point are unsupported. NULL %s is an empty string.
 * Unknown conversions print '%' and the conversion byte without consuming an
 * argument. Returns the number of characters passed to the console, or -1 for
 * a NULL format or output error. A count beyond INT_MAX
 * also returns -1. Output may already be partially written. */
int zx_console_printf(const char *format, ...);
/* va_list form of zx_console_printf, with the same format rules and return values. */
int zx_console_vprintf(const char *format, va_list args);

#endif
