#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t bc_fdd_overlay_get(uint8_t *mask) {
    uint8_t irq, bf;
    if (!mask) return ZX_INVALID_ARGUMENT;
    irq = zx_interrupt_save_disable();
    bf = z80_inp(BC_PORT_BF);
    if (bf == 0xffu) {
        zx_interrupt_restore(irq);
        return ZX_UNAVAILABLE;
    }
    *mask = (uint8_t)(z80_inp(0x13bdu) & 0x0fu);
    zx_interrupt_restore(irq);
    return ZX_OK;
}
