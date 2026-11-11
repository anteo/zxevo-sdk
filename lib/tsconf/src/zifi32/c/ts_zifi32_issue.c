#include <tsconf/zifi32.h>
#include "../../spi/internal.h"

zx_status_t ts_zifi32_issue(uint8_t command, const void *arguments, uint8_t length) {
    if (!command || (length && !arguments) || length > TS_ZIFI32_REGISTER_COUNT - 2u) {
        return ZX_INVALID_ARGUMENT;
    }

    ts_spi_select(TS_SPI_ESP32);
    ts_spi_write(0x01);
    ts_spi_write(0);
    ts_spi_write(0);
    ts_spi_write(command);
    ts_spi_write(TS_ZIFI32_IDLE);
    if (length) {
        ts__spi_write_payload(arguments, length);
    }
    ts_spi_select(TS_SPI_RELEASE);
    return ZX_OK;
}
