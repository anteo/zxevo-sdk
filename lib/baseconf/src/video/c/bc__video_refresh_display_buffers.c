#include "../internal.h"

uint8_t bc__video_refresh_display_buffers(void) {
    uint16_t snapshot = bc__video_read_mode_and_eff7();
    uint8_t mode = (uint8_t)snapshot;
    zx_status_t status = ZX_OK;
    uint8_t index, addressing = (uint8_t)(snapshot >> 8) & 4u;

    if (!bc_video_prepared_buffers[0].window0_high && !bc_video_prepared_buffers[1].window0_high)
        return mode;

    if (mode == ZX_VIDEO_UNKNOWN) status = ZX_UNAVAILABLE;
#ifndef BASECONF_VIDEO_ALL_MODES
    else if (!bc__video_mode_enabled((bc_video_mode_t)mode))
        status = ZX_UNSUPPORTED;
#endif
    for (index = 0; index < ZX_DRAW_BUFFER_SLOTS; ++index) {
        bc__draw_buffer_t *buffer = &bc_video_prepared_buffers[index];
        uint8_t delta;
        if (!buffer->window0_high) continue;
        buffer->display_status = status;
        if (status != ZX_OK) continue;

        delta = buffer->page0 - bc__video_first_screen_pages[mode];
        if (delta != 0 && delta != 2) {
            buffer->display_status = ZX_INVALID_ARGUMENT;
            continue;
        }
        /* Page delta 0 or 2 supplies the hardware screen bit. */
        buffer->display_flags = addressing | (delta << 2);
    }
    return mode;
}
