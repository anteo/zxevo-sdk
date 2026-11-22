#include "../internal.h"

zx_status_t zx_fdd_reg_write(zx_fdd_reg_t reg, uint8_t value) {
    uint8_t irq, bf;
    zx_status_t status;
    if ((uint8_t)reg > (uint8_t)ZX_FDD_DATA) return ZX_INVALID_ARGUMENT;
    status = bc__storage_fdd_shadow_begin(&irq, &bf);
    if (status != ZX_OK) return status;
    status = bc__storage_fdd_reg_context();
    if (status == ZX_OK) z80_outp(bc__storage_fdd_reg_port(reg), value);
    bc__storage_fdd_shadow_end(irq, bf);
    return status;
}
