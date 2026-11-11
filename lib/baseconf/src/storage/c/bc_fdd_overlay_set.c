#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t bc_fdd_overlay_set(uint8_t mask) {
    uint8_t irq, bf, old, readback;
    if (mask & 0xf0u) return ZX_INVALID_ARGUMENT;
    irq = zx_interrupt_save_disable();
    bf = z80_inp(BC_PORT_BF);
    if (bf == 0xffu) {
        zx_interrupt_restore(irq);
        return ZX_UNAVAILABLE;
    }
    old = (uint8_t)(z80_inp(0x13bdu) & 0x0fu);
    z80_outp(0x13bd, mask);
    readback = z80_inp(0x13bdu);
    if ((readback & 0x0fu) != mask) {
        z80_outp(0x13bdu, old);
        readback = z80_inp(0x13bdu);
    }
    zx_interrupt_restore(irq);
    return ((readback & 0x0fu) == mask) ? ZX_OK : ZX_UNSAFE_CONTEXT;
}
