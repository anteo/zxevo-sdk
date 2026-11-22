#include "../internal.h"

zx_status_t zx_fdd_reg_read(zx_fdd_reg_t reg, uint8_t *value) {
    uint8_t irq, bf;
    zx_status_t status;
    if (!value) return ZX_INVALID_ARGUMENT;
    if ((uint8_t)reg > (uint8_t)ZX_FDD_DATA) return ZX_INVALID_ARGUMENT;
    status = bc__storage_fdd_shadow_begin(&irq, &bf);
    if (status != ZX_OK) return status;
    status = bc__storage_fdd_reg_context();
    if (status == ZX_OK) *value = z80_inp(bc__storage_fdd_reg_port(reg));
    bc__storage_fdd_shadow_end(irq, bf);
    return status;
}
