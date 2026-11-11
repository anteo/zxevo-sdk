#include <tsconf.h>
#include <zx_test.h>

int main(void) {
    volatile uint8_t *w0 = (volatile uint8_t *)0x1000;
    volatile uint8_t *w1 = (volatile uint8_t *)0x5000;
    volatile uint8_t *w3 = (volatile uint8_t *)0xd000;
    ts_window_lease_t lease = {0};
    ts_window_lease_t other = {0};
    zx_status_t status;
    uint8_t page2;
    uint8_t alias;

    zx_test_init();
    ts_io_set_system_config(0);
    ts_io_set_interrupt_mask(0);
    /* Startup may already have consumed the cold-boot flag. The second
     * read must always have it cleared, regardless of the video build. */
    (void)ts_io_read_status();
    ZX_ASSERT(!(ts_io_read_status() & TS_STATUS_COLD_BOOT));
    zx_test_step_marker("status");

    page2 = ts_memory_get_page2();
    ZX_ASSERT(ts_map_ram_page(ZX_WINDOW_3, 0x81) == ZX_OK);
    *w3 = 0x5a;
    ZX_ASSERT(ts_memory_get_page3() == 0x81);
    ts_memory_set_page3(0x01);
    *w3 = 0xa5;
    ZX_ASSERT(ts_memory_get_page3() == 0x01);
    ts_memory_set_page3(0x81);
    ZX_ASSERT(*w3 == 0x5a);
    ZX_ASSERT(ts_memory_get_page2() == page2);
    zx_test_step_marker("w3-pages");

    ZX_ASSERT(ts_map_ram_page(ZX_WINDOW_0, 0x01) == ZX_UNSUPPORTED);
    ZX_ASSERT(ts_map_ram_page((zx_window_t)4, 0x01) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_window_acquire(ZX_WINDOW_1, 0x01, &lease) == ZX_UNSUPPORTED);
    ZX_ASSERT(ts_window_acquire(ZX_WINDOW_3, 0x01, NULL) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_window_acquire(ZX_WINDOW_3, 0x01, &lease) == ZX_OK);
    ZX_ASSERT(ts_memory_get_page3() == 0x01 && *w3 == 0xa5);
    ZX_ASSERT(ts_window_acquire(ZX_WINDOW_3, 0x81, &other) == ZX_BUSY);
    ZX_ASSERT(ts_map_ram_page(ZX_WINDOW_3, 0x81) == ZX_BUSY);
    other = lease;
    ZX_ASSERT(ts_window_release(&other) == ZX_BUSY);
    ZX_ASSERT(ts_memory_get_page3() == 0x01);
    ZX_ASSERT(ts_window_release(&lease) == ZX_OK);
    ZX_ASSERT(ts_window_release(&lease) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_memory_get_page3() == 0x81 && *w3 == 0x5a);
    zx_test_step_marker("w3-lease");

    /* Keep the mailbox on its resident page whenever the harness runs. */
    *w1 = 0;
    status = ts_map_ram_page(ZX_WINDOW_1, 0x81);
    alias = *w1;
    ts_memory_set_page1(TS_TEST_DATA_PAGE);
    ZX_ASSERT(status == ZX_OK && alias == 0x5a);
    zx_test_step_marker("w1-page-alias");

    ts_memory_set_page0(0x81);
    ts_memory_set_config(TS_MEM_W0_DIRECT | TS_MEM_W0_RAM | TS_MEM_W0_WRITE);
    ZX_ASSERT(*w0 == 0x5a);
    *w0 = 0x69;
    ZX_ASSERT(*w3 == 0x69);
    ts_memory_set_page0(0x01);
    ZX_ASSERT(*w0 == 0xa5);
    ts_memory_set_config(TS_MEM_W0_DIRECT);
    ts_memory_set_page0(3);
    zx_test_step_marker("w0-ram");

    zx_test_finish();
    return 0;
}
