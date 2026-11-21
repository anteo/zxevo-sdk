#include <baseconf.h>
#include "../internal.h"
#include "../../memory/internal.h"

/* xx77 mode bits, indexed by the public BaseConf mode numbers. The first
 * three modes use the same xx77 value and are distinguished by EFF7. */
static const uint8_t video_by_mode[] = {3, 3, 3, 0, 2, 6, 7};

zx_status_t zx_set_video_mode(uint16_t mode_number) {
    bc_video_mode_t mode;
    zx_status_t status;
    uint8_t eff7, displayed_mode;
    uint8_t sys;

    if (mode_number > BC_VIDEO_EVO_TEXT_80) return ZX_INVALID_ARGUMENT;
    mode = (bc_video_mode_t)mode_number;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled(mode)) return ZX_UNSUPPORTED;
#endif
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_mem_active_window_lease || bc_video_operation_depth) return ZX_BUSY;

    sys = bc_readback_register(0x0c);
    eff7 = (uint8_t)(bc_readback_register(0x0b) & (uint8_t)~0x21u);
    if (mode == BC_VIDEO_ZX_MULTICOLOR) eff7 |= 0x20u;
    if (mode == BC_VIDEO_PENTAGON_256) eff7 |= 0x01u;
    /* Revalidate the draw context after updating the FPGA mode registers. */
    bc__video_invalidate_draw_cache();
    status = bc__mem_write_eff7(eff7);
    if (status == ZX_OK) {
        uint8_t bf = bc__mem_shadow_scope_begin();
        z80_outp(bc__video_system_port(0), (uint8_t)((sys & 0x08u) | video_by_mode[mode]));
        bc__mem_shadow_scope_end(bf);
    }
    displayed_mode = bc__video_refresh_display_buffers();
    if (status != ZX_OK) return status;
    return displayed_mode == mode ? ZX_OK : ZX_UNSAFE_CONTEXT;
}
