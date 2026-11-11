#include <tsconf/zifi32.h>
#include "../../spi/internal.h"

zx_status_t ts_zifi32_write_data(const void *buffer, uint16_t length) {
    if (!buffer || !length || length > TS_ZIFI32_MAX_DATA || (length & 3u)) {
        return ZX_INVALID_ARGUMENT;
    }

    ts_spi_select(TS_SPI_ESP32);
    ts_spi_write(0x03);
    ts_spi_write(0);
    ts_spi_write(0);
    ts__spi_write_payload(buffer, length);
    ts_spi_select(TS_SPI_RELEASE);

    ts_spi_select(TS_SPI_ESP32);
    ts_spi_write(0x07);
    /* Match the pinned Raspberry Pi host's write-end transaction. */
    ts_spi_write(0);
    ts_spi_select(TS_SPI_RELEASE);
    return ZX_OK;
}
