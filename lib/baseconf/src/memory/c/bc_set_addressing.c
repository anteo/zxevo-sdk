#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"
#include "../../video/internal.h"

zx_status_t bc_set_addressing(bc_addressing_t addressing) {
    uint8_t eff7;
    zx_status_t status;
    if (addressing > BC_ADDRESSING_128K) return ZX_INVALID_ARGUMENT;
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_video_operation_depth) return ZX_BUSY;
    eff7 = bc_readback_register(0x0b);
    eff7 = addressing == BC_ADDRESSING_128K ? (uint8_t)(eff7 | 4u) : (uint8_t)(eff7 & (uint8_t)~4u);
    status = bc__mem_write_eff7(eff7);
    if (status == ZX_OK) bc__video_invalidate_cache();
    return status;
}
