#ifndef BASECONF_NEWIRQ_H
#define BASECONF_NEWIRQ_H

#include <stdint.h>
#include <baseconf.h>

typedef struct {
    uint8_t pending, source;
} bc_newirq_status_t;

/* Enable (nonzero) or disable (zero) newirq. Only vector_flags bits 1..2 are
 * written as vector-selection flags; all other bits are ignored and automatic
 * acknowledgement stays disabled. Does not execute EI/DI or install a handler. */
void bc_newirq_configure(uint8_t enabled, uint8_t vector_flags);
/* Replace the enabled-source mask (bits 0..6). Returns ZX_UNAVAILABLE until
 * newirq is enabled and ZX_INVALID_ARGUMENT if bit 7 is set. */
zx_status_t bc_newirq_enable_sources(uint8_t mask);
/* Clear pending requests selected by mask bits 0..6; unselected bits remain.
 * Returns ZX_UNAVAILABLE if disabled, ZX_INVALID_ARGUMENT if bit 7 is set. */
zx_status_t bc_newirq_acknowledge(uint8_t mask);
/* Read pending requests in bits 0..6; source is always zero because the RTL
 * exposes no active-source register. Returns ZX_INVALID_ARGUMENT for NULL
 * status and ZX_UNAVAILABLE when newirq is disabled. */
zx_status_t bc_newirq_status(bc_newirq_status_t *status);

#endif
