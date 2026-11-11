#include "../internal.h"

zx_status_t ts_ft812_write(uint32_t address, const void *buffer, uint16_t length) {
    zx_status_t status;

    if (length && !buffer) return ZX_INVALID_ARGUMENT;
    status = ts__ft812_begin(address, length, TS__FT812_WRITE);
    if (status == ZX_OK && length) {
        ts__spi_write_payload(buffer, length);
        ts_spi_select(TS_SPI_RELEASE);
    }
    return status;
}
