#include "../internal.h"

zx_status_t zx_avr_window_select(zx_avr_window_t type) {
    if (type > ZX_AVR_WINDOW_MODES && type != TS_AVR_WINDOW_CONFIG &&
        type != TS_AVR_WINDOW_SPI_FLASH)
        return ZX_INVALID_ARGUMENT;
    return zx__avr_window_set(type);
}
