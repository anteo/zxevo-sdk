#include <arch/z80.h>
#include <tsconf/copper.h>
#include <tsconf/fdr.h>
#include <tsconf/memory.h>
#include <tsconf/video.h>
#include <zx_test.h>

int main(void) {
    volatile uint8_t *const copper = (volatile uint8_t *)0xc600u;
    static const uint16_t words[] = {TS_COPPER_WAIT_Y(300), TS_COPPER_WRITE(0x0f, 0x38),
                                     TS_COPPER_SIGNAL(TS_COPPER_SIGNAL_READY), TS_COPPER_RETURN};
    uint32_t count = 0;

    zx_test_init();
    ts_memory_set_page3(0x60);
    ts_fmaps_enable(0xc000);
    ZX_ASSERT(ts_copper_upload(0xc001, 0, words, 4) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_copper_upload(0xc000, 253, words, 4) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_copper_upload(0xc000, 252, words, 4) == ZX_OK);
    ts_fmaps_disable();
    /* ZEsarUX has no Copper core. Observe the underlying RAM writes. */
    ZX_ASSERT(copper[504] == 0x2c && copper[505] == 0xfb);
    ZX_ASSERT(copper[506] == 0x38 && copper[507] == 0x0f);
    ZX_ASSERT(copper[508] == 0x02 && copper[509] == 0xf5);
    ZX_ASSERT(copper[510] == 0xff && copper[511] == 0xff);
    ZX_ASSERT(ts_copper_start(252) == ZX_OK);
    ZX_ASSERT(ts_copper_start(255) == ZX_INVALID_ARGUMENT);
    zx_test_step_marker("copper-start");
    ts_copper_stop();
    zx_test_step_marker("copper-stop");

    ZX_ASSERT(ts_fdr_read_count(0) == ZX_INVALID_ARGUMENT);
    ts_fdr_set_capture(1);
    zx_test_step_marker("capture-on");
    /* Seed the emulator's register shadow to exercise the count decoder. */
    z80_outp(0x30af, 0x56);
    z80_outp(0x31af, 0x34);
    z80_outp(0x32af, 0xfa);
    ZX_ASSERT(ts_fdr_read_count(&count) == ZX_OK && count == 0x023456ul);
    ts_fdr_set_capture(0);
    zx_test_step_marker("capture-off");
    zx_test_finish();
    return 0;
}
