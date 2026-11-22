#include "internal.h"

zx_status_t bc_basic48_video_end(void) {
    bc__basic48_video_t *s = &bc__basic48_video;
    zx_status_t status;
    uint8_t irq;
    if (!s->phase) return ZX_UNAVAILABLE;
    if (bc_video_operation_depth || bc_mem_active_window_lease) return ZX_BUSY;
    irq = zx_interrupt_save_disable();
    if (s->phase == BC_BASIC48_DRAWING) {
        bc__basic48_release_windows();
        irq = s->irq;
        s->phase = BC_BASIC48_WINDOWS_RELEASED;
    }
    status = zx_set_video_mode(ZX_VIDEO_ZX_256);
    /* One write restores both the original screen and BASIC's paging lock. */
    z80_outp(0x7ffd, s->paging);
    if (bc_readback_register(0x0a) != s->paging) status = ZX_UNSAFE_CONTEXT;
    if (status == ZX_OK) status = zx_set_draw_buffer(ZX_VIDEO_ZX_256, 5, ZX_WINDOW_1);
    zx_set_border_color(s->border);
    if (status == ZX_OK) s->phase = BC_BASIC48_IDLE;
    zx_interrupt_restore(irq);
    return status;
}
