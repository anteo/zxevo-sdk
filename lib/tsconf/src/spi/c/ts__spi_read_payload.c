#include "../internal.h"

void ts__spi_read_payload(void *buffer, uint16_t length) {
    uint8_t *out = buffer;

    (void)ts_spi_read_previous();
    while (--length) *out++ = ts_spi_read_previous();
    ts_spi_select(TS_SPI_RELEASE);
    *out = ts_spi_read_previous();
}
