#include <baseconf.h>
#include <baseconf/storage.h>
#include "../internal.h"
#include "../../memory/internal.h"

zx_status_t bc_fdd_select(zx_fdd_drive_t drive) {
    uint8_t bf, status, data, config;
    uint16_t palette_closed_port, restore_port;
    if (drive > ZX_FDD_DRIVE_D) return ZX_INVALID_ARGUMENT;
    bf = bc__mem_shadow_scope_begin();
    status = z80_inp(0x00ff);
    data = (uint8_t)((drive & 3u) | (status & 0x0cu) | ((~status) & 0x10u));
    config = bc_readback_register(0x0c);
    palette_closed_port = bc__storage_fdd_system_port(config, 1);
    restore_port = bc__storage_fdd_system_port(config, 0);
    z80_outp(palette_closed_port, (uint8_t)(config & 0x0fu));
    if (!(bc_readback_register(0x0c) & 0x80u)) {
        z80_outp(restore_port, (uint8_t)(config & 0x0fu));
        bc__mem_shadow_scope_end(bf);
        return ZX_UNSAFE_CONTEXT;
    }
    z80_outp(0x00ff, data);
    z80_outp(restore_port, (uint8_t)(config & 0x0fu));
    status = (uint8_t)(bc_readback_register(0x0c) ^ config);
    bc__mem_shadow_scope_end(bf);
    return (status & 0x80u) ? ZX_UNSAFE_CONTEXT : ZX_OK;
}
