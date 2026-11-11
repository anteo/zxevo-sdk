#include <baseconf.h>
#include "../internal.h"
#include "../../video/internal.h"

zx_status_t bc_set_readback_backend(bc_readback_backend_t backend) {
    if (backend > BC_READBACK_BE) return ZX_INVALID_ARGUMENT;
    if (bc_mem_active_window_lease) return ZX_BUSY;
    if (bc_video_operation_depth) return ZX_BUSY;
    if (bc_mem_readback_backend == backend) return ZX_OK;
    if (bc_mem_initialized && bc__mem_readback_is_unsafe(backend)) return ZX_UNSAFE_CONTEXT;
    bc_mem_readback_backend = backend;
    if (bc_mem_initialized) {
        bc__mem_refresh_all_windows();
        bc__video_invalidate_cache();
    }
    return ZX_OK;
}
