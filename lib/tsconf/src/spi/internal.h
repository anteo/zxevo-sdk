#ifndef TSCONF_SPI_INTERNAL_H
#define TSCONF_SPI_INTERNAL_H

#include <tsconf/spi.h>

/* Read a nonempty payload after the last header byte. Release CS before
 * retrieving the last result so the final IN clocks no byte to the device. */
void ts__spi_read_payload(void *buffer, uint16_t length);

/* Shift a payload through the selected device and leave its CS asserted. */
void ts__spi_write_payload(const void *buffer, uint16_t length);

#endif
