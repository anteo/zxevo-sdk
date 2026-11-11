#include <tsconf/rtc.h>
#include <zx_test.h>

int main(void) {
    uint8_t original, byte = 0x69;

    zx_test_init();
    ts_rtc_set_enabled(1);
    ZX_ASSERT(zx_nvram_read(0x0e, &byte) == ZX_INVALID_ARGUMENT && byte == 0x69);
    ZX_ASSERT(zx_nvram_write(0xf0, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_rtc_read((zx_rtc_index_t)0x0f, &byte) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_rtc_write(ZX_RTC_MODIFIERS, 0) == ZX_INVALID_ARGUMENT);
    original = 0;
    ZX_ASSERT(zx_nvram_read(0x70, &original) == ZX_OK);
    ZX_ASSERT(zx_nvram_write(0x70, (uint8_t)(original ^ 0xa5u)) == ZX_OK);
    ZX_ASSERT(zx_nvram_read(0x70, &byte) == ZX_OK && byte == (uint8_t)(original ^ 0xa5u));
    ZX_ASSERT(zx_nvram_write(0x70, original) == ZX_OK);
    ZX_ASSERT(zx_nvram_read(0x70, &byte) == ZX_OK && byte == original);
    zx_test_step_marker("nvram-ports");
    ts_rtc_set_enabled(0);
    zx_test_finish();
    return 0;
}
