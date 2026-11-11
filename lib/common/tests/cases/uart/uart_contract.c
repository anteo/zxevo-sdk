#include <zx/uart.h>
#include <zx_test.h>

#if defined(__BASECONF)
#include <arch/z80.h>
#include "bc_case.h"
#endif

static void check_arguments(void) {
    const zx_uart_config_t bad_bits = {(zx_uart_data_bits_t)4, ZX_UART_PARITY_NONE, 1, 1};
    const zx_uart_config_t bad_parity = {ZX_UART_BITS_8, (zx_uart_parity_t)3, 1, 1};
    const zx_uart_config_t bad_stop = {ZX_UART_BITS_8, ZX_UART_PARITY_NONE, 3, 1};
    uint8_t byte = 0xa5;

    ZX_ASSERT(zx_uart_configure(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_uart_configure(&bad_bits) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_uart_configure(&bad_parity) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_uart_configure(&bad_stop) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_uart_status(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_uart_modem_status(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_uart_receive(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_uart_wait_receive_polls(0, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_uart_wait_receive_polls(&byte, 0) == ZX_BUSY && byte == 0xa5);
    zx_test_step_marker("arguments");
}

#if defined(__BASECONF)
static void check_exchange(void) {
    static const uint8_t rx[] = {0x00, 0xff, 0x0d, 0x0a, 0x80, 0x13, 0x11};
    static const uint8_t tx[] = {0x55, 0xaa, 0x0a, 0x0d, 0x00, 0xff};
    const zx_uart_config_t config = {ZX_UART_BITS_8, ZX_UART_PARITY_NONE, 1, 1};
    zx_uart_status_t status;
    zx_uart_modem_status_t modem;
    uint8_t byte = 0xa5;
    uint8_t i;
    uint16_t polls;

    ZX_ASSERT(zx_uart_configure(&config) == ZX_OK);
    ZX_ASSERT(z80_inp(0xfbef) == 3 && (z80_inp(0xfcef) & 2));
    z80_outp(0xfbef, 0x83);
    /* FPGA ignores A15..A11 when selecting the UART register. */
    ZX_ASSERT(z80_inp(0x00ef) == 1 && z80_inp(0x01ef) == 0);
    z80_outp(0xfbef, 3);
    ZX_ASSERT(zx_uart_status(&status) == ZX_OK && !status.rx_ready && status.tx_ready);
    ZX_ASSERT(zx_uart_receive(&byte) == ZX_BUSY && byte == 0xa5);
    ZX_ASSERT(zx_uart_modem_status(&modem) == ZX_OK && modem.cts && modem.dsr && modem.dcd);
    ZX_ASSERT(zx_uart_modem_status(&modem) == ZX_OK && !modem.cts_changed);
    zx_test_step_marker("ready");

    for (polls = 0; polls < 4096; ++polls) {
        ZX_ASSERT(zx_uart_status(&status) == ZX_OK);
        if (status.rx_half_full) break;
    }
    ZX_ASSERT(status.rx_ready && status.rx_half_full);
    ZX_ASSERT(!status.framing_error && !status.parity_error && !status.overrun);
    ZX_ASSERT(zx_uart_wait_receive_polls(&byte, 4096) == ZX_OK && byte == rx[0]);
    for (i = 1; i < sizeof(rx); ++i) {
        ZX_ASSERT(zx_uart_receive(&byte) == ZX_OK && byte == rx[i]);
    }
    ZX_ASSERT(zx_uart_status(&status) == ZX_OK && status.rx_ready && !status.rx_half_full);
    ZX_ASSERT(zx_uart_configure(&config) == ZX_OK);
    ZX_ASSERT(zx_uart_receive(&byte) == ZX_BUSY && byte == rx[sizeof(rx) - 1]);
    zx_test_step_marker("receive");

    for (i = 0; i < sizeof(tx); ++i) {
        ZX_ASSERT(zx_uart_send(tx[i]) == ZX_OK);
    }
    zx_test_step_marker("transmit");
}
#endif

int main(void) {
#if defined(__BASECONF)
    if (bc_case_init() == ZX_OK) {
        check_arguments();
        check_exchange();
    }
#else
    zx_test_init();
    check_arguments();
    zx_test_step_skip("exchange", "ZEsarUX TSConf bridges ZiFi, not the Kondratyev UART");
#endif
    zx_test_finish();
    return 0;
}
