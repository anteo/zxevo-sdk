#include <tsconf/ft812.h>

void ts_ft812_set_pclk(uint8_t divider) __z88dk_fastcall {
    ts_ft812_write(TS_FT812_REG_PCLK, &divider, 1);
}
