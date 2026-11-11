#include <tsconf/zifi32.h>
#include "../../spi/internal.h"

zx_status_t ts_zifi32_read_data(void *buffer, uint16_t length) {
    if (!buffer || !length || length > TS_ZIFI32_MAX_DATA || (length & 3u)) {
        return ZX_INVALID_ARGUMENT;
    }

    ts_spi_select(TS_SPI_ESP32);
    ts_spi_write(0x04);
    ts_spi_write(0);
    ts_spi_write(0);
    ts__spi_read_payload(buffer, length);

    ts_spi_select(TS_SPI_ESP32);
    ts_spi_write(0x08);
    ts_spi_select(TS_SPI_RELEASE);
    return ZX_OK;
}
