#ifndef TSCONF_ZIFI_H
#define TSCONF_ZIFI_H

#include <stdint.h>
#include <zx/status.h>

typedef enum { TS_ZIFI_WIFI = 0, TS_ZIFI_RS232 = 1 } ts_zifi_channel_t;

#define TS_ZIFI_RESET_RX 0x01u
#define TS_ZIFI_RESET_TX 0x02u
#define TS_ZIFI_WIFI_THRESHOLD 0x01u
#define TS_ZIFI_WIFI_TIMEOUT 0x02u
#define TS_ZIFI_RS232_THRESHOLD 0x04u
#define TS_ZIFI_RS232_TIMEOUT 0x08u

/* Enable the legacy FIFO API and query its version. Version 1 is supported
 * by the pinned AVR. Disable releases the FIFO API. */
uint8_t ts_zifi_enable(void);
void ts_zifi_disable(void);

/* Clear the selected channel's RX and/or TX FIFO. directions is a nonempty
 * combination of TS_ZIFI_RESET_RX/TX. The caller owns the shared FIFO API. */
zx_status_t ts_zifi_reset_fifo(ts_zifi_channel_t channel, uint8_t directions);

/* Transfer up to limit bytes without blocking. Return the number transferred
 * or zero for an invalid channel, NULL buffer, zero budget or empty/full FIFO.
 * Reading the channel status selects it for data accesses. Serialize status
 * and FIFO accesses against other users, including IRQ handlers. */
uint8_t ts_zifi_read(ts_zifi_channel_t channel, void *buffer, uint8_t limit);
uint8_t ts_zifi_write(ts_zifi_channel_t channel, const void *buffer, uint8_t limit);

/* Set the RX threshold in bytes and inactivity timeout in milliseconds.
 * Configure these before arming the corresponding events. */
zx_status_t ts_zifi_set_rx_events(ts_zifi_channel_t channel, uint8_t threshold, uint8_t timeout_ms);
/* Read and acknowledge pending events. Events disarm until armed again. */
uint8_t ts_zifi_read_events(void);
/* Replace the armed-event mask. TS_IRQ_AVR enables delivery to the CPU. */
void ts_zifi_arm_events(uint8_t events) __z88dk_fastcall;

#endif
