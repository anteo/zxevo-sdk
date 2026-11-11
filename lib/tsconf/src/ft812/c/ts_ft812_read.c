#include "../internal.h"

zx_status_t ts_ft812_read(uint32_t address, void *buffer, uint16_t length) {
    zx_status_t status;

    if (length && !buffer) return ZX_INVALID_ARGUMENT;
    status = ts__ft812_begin(address, length, 0);
    if (status == ZX_OK && length) {
        ts_spi_write(0);
        ts__spi_read_payload(buffer, length);
    }
    return status;
}
