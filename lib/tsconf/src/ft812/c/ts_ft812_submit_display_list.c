#include <tsconf/ft812.h>

zx_status_t ts_ft812_submit_display_list(const uint32_t *words, uint16_t count) {
    uint8_t swap;

    if (!words || !count || count > TS_FT812_DL_WORDS || words[count - 1] != TS_FT812_DL_DISPLAY)
        return ZX_INVALID_ARGUMENT;

    ts_ft812_read(TS_FT812_REG_DLSWAP, &swap, 1);
    if (swap == 0xffu) return ZX_UNAVAILABLE;
    if (swap != TS_FT812_DLSWAP_DONE) return ZX_BUSY;

    ts_ft812_write(TS_FT812_RAM_DL, words, count * sizeof(*words));
    swap = TS_FT812_DLSWAP_FRAME;
    return ts_ft812_write(TS_FT812_REG_DLSWAP, &swap, 1);
}
