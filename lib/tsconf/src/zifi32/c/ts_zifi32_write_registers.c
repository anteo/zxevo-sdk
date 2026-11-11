#include <tsconf/zifi32.h>
#include "../../spi/internal.h"

zx_status_t ts_zifi32_write_registers(uint8_t first, const void *buffer, uint8_t length) {
    if (!buffer || !length || first >= TS_ZIFI32_REGISTER_COUNT ||
        length > TS_ZIFI32_REGISTER_COUNT - first) {
        return ZX_INVALID_ARGUMENT;
    }

    ts_spi_select(TS_SPI_ESP32);
    ts_spi_write(0x01);
    ts_spi_write(first);
    ts_spi_write(0);
    ts__spi_write_payload(buffer, length);
    ts_spi_select(TS_SPI_RELEASE);
    return ZX_OK;
}
