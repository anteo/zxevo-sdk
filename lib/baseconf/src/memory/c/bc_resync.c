#include <baseconf.h>
#include "../internal.h"
#include "../../internal.h"
#include "../../video/internal.h"

zx_status_t bc_resync(void) {
    zx_status_t status;
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease || bc_video_operation_depth) return ZX_BUSY;

    bc__mem_refresh_all_windows();
    bc__video_invalidate_cache();
    if (!bc_video_surface_selected) return ZX_OK;
    status = bc__video_sync_cache();
    return status;
}
