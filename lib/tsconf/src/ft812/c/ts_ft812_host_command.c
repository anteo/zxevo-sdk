#include <tsconf/ft812.h>
#include <tsconf/spi.h>

zx_status_t ts_ft812_host_command(uint8_t command, uint8_t parameter) {
    if (command ? (command & 0xc0u) != 0x40u : parameter != 0) return ZX_INVALID_ARGUMENT;

    ts_spi_select(TS_SPI_FT812);
    ts_spi_write(command);
    ts_spi_write(parameter);
    ts_spi_write(0);
    ts_spi_select(TS_SPI_RELEASE);
    return ZX_OK;
}
