#ifndef TSCONF_SPI_H
#define TSCONF_SPI_H

#include <stdint.h>

#define TS_SPI_SD1 0x01u
#define TS_SPI_RELEASE 0x03u
#define TS_SPI_FT812 0x07u
#define TS_SPI_SD2 0x0bu
#define TS_SPI_ESP32 0x13u
#define TS_SPI_ESP32_OVERRIDE_ON 0x82u
#define TS_SPI_ESP32_OVERRIDE_OFF 0x02u
#define TS_SPI_ESP32_SELECT_EVENT 0x80u

/* Write the SPI chip-select byte to 77h. The caller owns the bus and uses
 * a target supported by the FPGA build. Serialize with SD, TS-BIOS and DMA. */
void ts_spi_select(uint8_t selection) __z88dk_fastcall;

/* Read 77h. Standard builds return zero. On ESP32_SPI builds D7 reports
 * a select event during ESP32 override. Writing either OVERRIDE value
 * also clears that event and releases all ordinary chip selects. */
uint8_t ts_spi_read_config(void);

/* Shift one byte through 57h. A subsequent read returns its received byte. */
void ts_spi_write(uint8_t value) __z88dk_fastcall;

/* Return the previous received byte and start a new exchange with FFh.
 * A final read still clocks another byte while the device is selected. */
uint8_t ts_spi_read_previous(void);

#endif
