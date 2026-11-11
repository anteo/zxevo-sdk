#include "../internal.h"

void ts__spi_write_payload(const void *buffer, uint16_t length) {
    const uint8_t *source = buffer;
    while (length--) ts_spi_write(*source++);
}
