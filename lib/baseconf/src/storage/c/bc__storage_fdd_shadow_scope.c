#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t bc__storage_fdd_shadow_begin(uint8_t *irq, uint8_t *bf) {
    *irq = zx_interrupt_save_disable();
    *bf = z80_inp(BC_PORT_BF);
    if (*bf == 0xffu) {
        zx_interrupt_restore(*irq);
        return ZX_UNAVAILABLE;
    }
    if (*bf & 0x04u) {
        zx_interrupt_restore(*irq);
        return ZX_BUSY;
    }
    bc__mem_shadow_scope_open(*bf);
    return ZX_OK;
}

void bc__storage_fdd_shadow_end(uint8_t irq, uint8_t bf) {
    bc__mem_shadow_scope_end(bf);
    zx_interrupt_restore(irq);
}
