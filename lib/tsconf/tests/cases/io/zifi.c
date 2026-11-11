#include <tsconf/zifi.h>
#include <zx_test.h>

int main(void) {
    static const uint8_t transmit[] = {0x55, 0xaa, 0x0a, 0x00, 0xff};
    uint8_t receive[4] = {0};
    uint8_t count = 0;
    uint16_t budget;

    zx_test_init();
    ZX_ASSERT(ts_zifi_read((ts_zifi_channel_t)2, receive, 1) == 0);
    ZX_ASSERT(ts_zifi_read(TS_ZIFI_WIFI, 0, 1) == 0);
    ZX_ASSERT(ts_zifi_write(TS_ZIFI_WIFI, transmit, 0) == 0);
    ZX_ASSERT(ts_zifi_reset_fifo(TS_ZIFI_WIFI, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi_set_rx_events((ts_zifi_channel_t)2, 1, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi_read(TS_ZIFI_WIFI, receive, sizeof(receive)) == 0);
    zx_test_step_marker("ready");

    /* ZEsarUX reports one available byte at a time. Real firmware reports
     * the FIFO count, so the same loop also works with larger prefixes. */
    for (budget = 0; budget < 4096 && count < sizeof(receive); ++budget)
        count += ts_zifi_read(TS_ZIFI_WIFI, receive + count, sizeof(receive) - count);
    ZX_ASSERT(count == sizeof(receive));
    ZX_ASSERT(receive[0] == 0 && receive[1] == 0xff && receive[2] == 0x0d && receive[3] == 0x80);
    zx_test_step_marker("receive");

    count = 0;
    for (budget = 0; budget < 4096 && count < sizeof(transmit); ++budget)
        count += ts_zifi_write(TS_ZIFI_WIFI, transmit + count, sizeof(transmit) - count);
    ZX_ASSERT(count == sizeof(transmit));
    zx_test_step_marker("transmit");
    zx_test_finish();
    return 0;
}
