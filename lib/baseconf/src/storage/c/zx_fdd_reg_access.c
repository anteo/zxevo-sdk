#include "../internal.h"

static uint16_t fdd_reg_port(zx_fdd_reg_t reg) {
    static const uint8_t ports[] = {0x1f, 0x3f, 0x5f, 0x7f};
    return (uint16_t)ports[(uint8_t)reg];
}

static zx_status_t fdd_reg_context(void) {
    /* FE interception swallows WD1793 accesses when its other conditions hold;
     * the library cannot safely infer ROM/DOS/window state from 13BD alone. */
    return (z80_inp(0x13bdu) & 0x0fu) ? ZX_UNSAFE_CONTEXT : ZX_OK;
}

zx_status_t zx_fdd_reg_read(zx_fdd_reg_t reg, uint8_t *value) {
    uint8_t irq, bf;
    zx_status_t status;
    if (!value) return ZX_INVALID_ARGUMENT;
    if ((uint8_t)reg > (uint8_t)ZX_FDD_DATA) return ZX_INVALID_ARGUMENT;
    status = bc__storage_fdd_shadow_begin(&irq, &bf);
    if (status != ZX_OK) return status;
    status = fdd_reg_context();
    if (status == ZX_OK) *value = z80_inp(fdd_reg_port(reg));
    bc__storage_fdd_shadow_end(irq, bf);
    return status;
}

zx_status_t zx_fdd_reg_write(zx_fdd_reg_t reg, uint8_t value) {
    uint8_t irq, bf;
    zx_status_t status;
    if ((uint8_t)reg > (uint8_t)ZX_FDD_DATA) return ZX_INVALID_ARGUMENT;
    status = bc__storage_fdd_shadow_begin(&irq, &bf);
    if (status != ZX_OK) return status;
    status = fdd_reg_context();
    if (status == ZX_OK) z80_outp(fdd_reg_port(reg), value);
    bc__storage_fdd_shadow_end(irq, bf);
    return status;
}
