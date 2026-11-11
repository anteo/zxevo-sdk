#include "../internal.h"
#include "../../../../common/src/fdd/internal.h"

zx_status_t zx_fdd_system_write(const zx_fdd_system_t *cfg) __z88dk_fastcall {
    uint8_t irq, bf, config;
    uint8_t data = zx__fdd_system_byte(cfg);
    uint16_t close_palette, restore_palette;
    zx_status_t status;
    if (data == 0xffu) return ZX_INVALID_ARGUMENT;
    status = bc__storage_fdd_shadow_begin(&irq, &bf);
    if (status != ZX_OK) return status;
    config = bc_readback_register(0x0c);
    close_palette = bc__storage_fdd_system_port(config, 1);
    restore_palette = bc__storage_fdd_system_port(config, 0);
    z80_outp(close_palette, (uint8_t)(config & 0x0fu));
    if (!(bc_readback_register(0x0c) & 0x80u)) {
        z80_outp(restore_palette, (uint8_t)(config & 0x0fu));
        bc__storage_fdd_shadow_end(irq, bf);
        return ZX_UNSAFE_CONTEXT;
    }
    z80_outp(0x00ffu, data);
    z80_outp(restore_palette, (uint8_t)(config & 0x0fu));
    status = ((bc_readback_register(0x0c) ^ config) & 0x80u) ? ZX_UNSAFE_CONTEXT : ZX_OK;
    bc__storage_fdd_shadow_end(irq, bf);
    return status;
}
