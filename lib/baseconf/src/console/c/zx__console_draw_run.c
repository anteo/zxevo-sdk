#include "../../../../common/src/console/internal.h"
#include "../internal.h"
#include "../../text/internal.h"
#include "../../video/internal.h"

zx_status_t zx__console_draw_run(uint8_t column, uint8_t row, const char *text, uint8_t length,
                                 zx_text_bg_t background) {
#ifdef BASECONF_VIDEO_TEXT_HARDWARE
    bc_surface_t surface = bc_video_draw_surface_state;

    if (surface.mode >= BC_VIDEO_ATM_TEXT_80) {
        zx_status_t status;
        if (background == ZX_TEXT_TRANSPARENT) return ZX_UNSUPPORTED;
        status = bc__video_begin();
        if (status != ZX_OK) return status;
        do {
            bc__text_cell_write(surface.mode, surface, column++, row, (uint8_t)*text++);
        } while (--length);
        return bc__video_end();
    }
#endif
    if (!bc_console_active_font) return ZX_NOT_INITIALIZED;
    return bc__text_draw_font(column, row, text, bc_console_active_font, length, background);
}
