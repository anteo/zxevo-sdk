#include "../internal.h"

zx_status_t ts__ft812_begin(uint32_t address, uint16_t length, uint8_t flag) {
    if (address > 0x400000ul || length > 0x400000ul - address) return ZX_INVALID_ARGUMENT;
    if (length) {
        ts_spi_select(TS_SPI_FT812);
        ts_spi_write((uint8_t)(address >> 16) | flag);
        ts_spi_write((uint8_t)(address >> 8));
        ts_spi_write((uint8_t)address);
    }
    return ZX_OK;
}
