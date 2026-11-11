#ifndef ZX_UART_H
#define ZX_UART_H

#include <stdint.h>
#include <zx/status.h>

/* Kondratyev UART at F8EFh..FFEFh. */
typedef enum { ZX_UART_PARITY_NONE, ZX_UART_PARITY_ODD, ZX_UART_PARITY_EVEN } zx_uart_parity_t;
typedef enum {
    ZX_UART_BITS_5 = 5,
    ZX_UART_BITS_6,
    ZX_UART_BITS_7,
    ZX_UART_BITS_8
} zx_uart_data_bits_t;
typedef struct {
    zx_uart_data_bits_t bits;
    zx_uart_parity_t parity;
    uint8_t stop_bits;
    uint16_t divisor;
} zx_uart_config_t;
typedef struct {
    uint8_t rx_ready;
    uint8_t rx_half_full; /* LSR.D7 on BaseConf. TSConf firmware leaves it clear. */
    uint8_t tx_ready, framing_error, parity_error, overrun;
} zx_uart_status_t;
typedef struct {
    uint8_t cts, dsr, dcd, ri, cts_changed;
} zx_uart_modem_status_t;

/* Configure 5..8 data bits, the selected parity, and 1 or 2 stop bits; divisor
 * is the raw 16-bit baud register value. Enables/resets the RX/TX FIFOs
 * (discarding buffered data), asserts RTS and preserves other modem controls.
 * Returns ZX_INVALID_ARGUMENT for NULL configuration or invalid framing. */
zx_status_t zx_uart_configure(const zx_uart_config_t *configuration);
/* Read FEEF modem status; reading clears the CTS-change latch. */
zx_status_t zx_uart_modem_status(zx_uart_modem_status_t *status);
/* Receive one byte without waiting; returns ZX_BUSY if no byte is ready and
 * ZX_INVALID_ARGUMENT for NULL byte. The output is unchanged on failure. */
zx_status_t zx_uart_receive(uint8_t *byte);
/* Send one byte without waiting; return ZX_BUSY when the transmitter is not ready. */
zx_status_t zx_uart_send(uint8_t byte);
/* Read receive/transmit readiness and line error flags into boolean fields.
 * Returns ZX_INVALID_ARGUMENT for NULL status, otherwise ZX_OK. */
zx_status_t zx_uart_status(zx_uart_status_t *status);
/* Poll receive status at most poll_budget times and read one byte when ready.
 * Returns ZX_OK after receiving, ZX_BUSY if the budget expires (including a
 * zero budget), or ZX_INVALID_ARGUMENT for NULL byte. The output is unchanged
 * on failure. The budget counts polls, not frames or elapsed time. */
zx_status_t zx_uart_wait_receive_polls(uint8_t *byte, uint16_t poll_budget);

#endif
