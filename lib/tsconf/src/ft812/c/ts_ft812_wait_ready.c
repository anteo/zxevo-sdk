#include <tsconf/ft812.h>

zx_status_t ts_ft812_wait_ready(uint16_t polls) __z88dk_fastcall {
    uint8_t value;

    while (polls--) {
        ts_ft812_read(TS_FT812_REG_ID, &value, 1);
        if (value == TS_FT812_ID) {
            ts_ft812_read(TS_FT812_REG_CPURESET, &value, 1);
            if (value == 0) return ZX_OK;
        }
    }
    return ZX_TIMEOUT;
}
