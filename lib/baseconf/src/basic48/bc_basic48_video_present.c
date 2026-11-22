#include "internal.h"

zx_status_t bc_basic48_video_present(void) {
    bc__basic48_video_t *s = &bc__basic48_video;
    zx_status_t status;
    if (s->phase != BC_BASIC48_DRAWING) return ZX_UNAVAILABLE;
    if (bc_video_operation_depth || bc_mem_active_window_lease) return ZX_BUSY;
    status = zx_set_video_mode(s->mode);
    if (status == ZX_OK) status = zx_display_page(s->page);
    if (status == ZX_OK) {
        bc__basic48_release_windows();
        s->phase = BC_BASIC48_WINDOWS_RELEASED;
        zx_interrupt_restore(s->irq);
    }
    return status;
}
