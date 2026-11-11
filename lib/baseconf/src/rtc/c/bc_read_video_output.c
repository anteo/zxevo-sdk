#include "../internal.h"

zx_status_t bc_read_video_output(bc_video_output_t *output) {
    zx__avr_window_scope_t state;
    uint8_t modes;
    zx_status_t status;

    if (!output) return ZX_INVALID_ARGUMENT;
    status = zx__avr_window_begin(ZX_AVR_WINDOW_MODES, &state);
    if (status != ZX_OK) return status;
    modes = zx__rtc_read_scoped(ZX__RTC_EXTENSION);
    zx__avr_window_end(&state);

    output->raster = (bc_raster_code_t)((modes >> 4) & 0x03u);
    output->vga = (uint8_t)(modes & 0x01u);
    output->tape_out = (uint8_t)((modes >> 1) & 0x01u);
    output->caps_led = (uint8_t)((modes >> 2) & 0x01u);
    return ZX_OK;
}
