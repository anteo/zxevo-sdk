#include "../internal.h"

zx_status_t zx_read_avr_version(zx_avr_window_t type, zx_avr_version_t *version) {
    zx__avr_window_scope_t scope;
    uint8_t bytes[16];
    uint8_t i;
    zx_status_t status;

    if (!version || (type != ZX_AVR_WINDOW_VERSION && type != ZX_AVR_WINDOW_BOOTLOADER))
        return ZX_INVALID_ARGUMENT;
    status = zx__avr_window_begin(type, &scope);
    if (status != ZX_OK) return status;
    for (i = 0; i < sizeof(bytes); ++i) bytes[i] = zx__rtc_read_scoped(ZX__RTC_EXTENSION + i);
    zx__avr_window_end(&scope);

    zx__avr_decode_version(bytes, version);
    return ZX_OK;
}
