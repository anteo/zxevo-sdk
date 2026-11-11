#ifndef TSCONF_ZIFI32_H
#define TSCONF_ZIFI32_H

#include <stdint.h>
#include <zx/status.h>

#define TS_ZIFI32_REGISTER_COUNT 64u
#define TS_ZIFI32_MAX_DATA 4000u

#define TS_ZIFI32_IDLE 0x00u
#define TS_ZIFI32_READY 0x01u
#define TS_ZIFI32_BUSY 0x02u
#define TS_ZIFI32_DATA_M2S 0x03u
#define TS_ZIFI32_DATA_S2M 0x04u
#define TS_ZIFI32_RESET 0x7eu

typedef struct {
    uint8_t api;
    uint16_t feature;
    uint8_t major;
    uint8_t minor;
    uint8_t patch;
} ts_zifi32_version_t;

/* ESP32-S3 ZiFi32 in single-bit SPI slave mode. Keep the Z80 in control of
 * the FT/ESP SPI lines. Override control and select events are in tsconf/spi.h.
 * Serialize access with all other SPI users, including DMA and interrupts,
 * and serialize command sequences with other ZiFi32 users. Each transaction
 * releases SPI. Buffers must remain CPU-visible. */

/* Transfer one nonempty range within the 64 shared registers. */
zx_status_t ts_zifi32_read_registers(uint8_t first, void *buffer, uint8_t length);
zx_status_t ts_zifi32_write_registers(uint8_t first, const void *buffer, uint8_t length);

/* Issue a nonzero firmware command when the previous one is complete.
 * Arguments, if any, are written at registers 2..63. Use zero length for
 * commands without arguments. Poll completion or data readiness separately. */
zx_status_t ts_zifi32_issue(uint8_t command, const void *arguments, uint8_t length);

/* Poll at most max_polls times for READY, RESET, DATA_M2S or DATA_S2M.
 * If status is supplied, it receives the last byte observed. FFh returns
 * ZX_UNAVAILABLE, firmware errors 80h..FEh return ZX_IO_ERROR. Polling that
 * exhausts the budget returns ZX_TIMEOUT. max_polls must be nonzero. */
zx_status_t ts_zifi32_wait_status(uint8_t expected, uint16_t max_polls, uint8_t *status);

/* Issue GET_VER and wait for READY. The output is set on success. */
zx_status_t ts_zifi32_get_version(ts_zifi32_version_t *version, uint16_t max_polls);

/* Transfer and terminate one firmware-negotiated data phase. First wait for
 * DATA_S2M before reading or DATA_M2S before writing. Use the agreed wire
 * length, a nonzero multiple of four up to TS_ZIFI32_MAX_DATA. Poll status
 * again afterward if the command needs a completion check. */
zx_status_t ts_zifi32_read_data(void *buffer, uint16_t length);
zx_status_t ts_zifi32_write_data(const void *buffer, uint16_t length);

#endif
