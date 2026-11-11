#include <zx/ps2.h>
#include "../../rtc/internal.h"

zx_status_t zx_ps2_scancode_read(uint8_t *code) {
    zx__avr_window_scope_t scope;
    zx_status_t status;
    uint8_t sample;

    if (!code) return ZX_INVALID_ARGUMENT;
    status = zx__avr_window_begin(ZX_AVR_WINDOW_PS2_LOG, &scope);
    if (status != ZX_OK) return status;
    sample = zx__rtc_read_scoped(ZX__RTC_EXTENSION);
    zx__avr_window_end(&scope);
    *code = sample;
    return ZX_OK;
}
