#include "internal.h"
#include "../../memory/internal.h"

zx_status_t zx_display_page(zx_ram_page_t page) {
    uint16_t mode;
    zx_screen_t screen;
    zx_status_t status;

    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (bc_video_operation_depth) return ZX_BUSY;
    mode = zx_get_video_mode();
    if (mode == ZX_VIDEO_UNKNOWN) return ZX_UNAVAILABLE;
    status = bc__video_find_screen(mode, page, &screen);
    if (status != ZX_OK) return status;
    return bc_select_screen(screen);
}
