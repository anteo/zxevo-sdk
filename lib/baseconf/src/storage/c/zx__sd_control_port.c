#include "../internal.h"
#include "../../memory/internal.h"
#include "../../../../common/src/sd/internal.h"

zx_status_t zx__sd_control_port(uint8_t *high) __z88dk_fastcall {
    uint8_t bf, system;
    bf = z80_inp(BC_PORT_BF);
    if (bf == 0xffu) return ZX_UNAVAILABLE;
    system = bc_readback_register(0x0c);
    /* DOS or BF.0 moves CS from 0077h to 8057h. A9 low forces DOS. */
    *high = (BC_CONFIG_SHADOW_PORTS(bf) || (system & 0x10u) || !(system & 0x40u)) ? 0x80 : 0;
    return ZX_OK;
}
