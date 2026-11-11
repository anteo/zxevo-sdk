#include <tsconf/ft812.h>

zx_status_t ts_ft812_wait_display_list(uint16_t polls) __z88dk_fastcall {
    uint8_t swap;

    while (polls--) {
        ts_ft812_read(TS_FT812_REG_DLSWAP, &swap, 1);
        if (swap == TS_FT812_DLSWAP_DONE) return ZX_OK;
        if (swap == 0xffu) return ZX_UNAVAILABLE;
    }
    return ZX_TIMEOUT;
}
