#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"

zx_status_t bc_get_paging_state(bc_paging_snapshot_t *state) {
    uint8_t xx77;
    if (!state) return ZX_INVALID_ARGUMENT;
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    state->saved_7ffd = bc_readback_register(0x0a);
    state->saved_eff7 = bc_readback_register(0x0b);
    xx77 = bc_readback_register(0x0c);
    state->saved_xx77_data = (uint8_t)(xx77 & 0x0fu);
    state->saved_xx77_address = bc__mem_xx77_port(xx77);
    return ZX_OK;
}
