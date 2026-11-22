#include "../internal.h"
#include "../../memory/internal.h"

void bc__storage_fdd_shadow_end(uint8_t irq, uint8_t bf) {
    bc__mem_shadow_scope_end(bf);
    zx_interrupt_restore(irq);
}
