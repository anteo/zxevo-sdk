#include <tsconf/ft812.h>

static uint8_t valid_axis(const ts_ft812_axis_t *axis) {
    return axis->cycle <= 4095u && axis->offset < axis->cycle && axis->size != 0 &&
           axis->size <= axis->cycle - axis->offset && axis->sync_start < axis->sync_end &&
           axis->sync_end <= axis->cycle;
}

static void write_axis(uint32_t address, const ts_ft812_axis_t *axis) {
    /* Each register occupies four bytes. Its low word contains the value. */
    ts_ft812_write(address, &axis->cycle, 2);
    ts_ft812_write(address + 4, &axis->offset, 2);
    ts_ft812_write(address + 8, &axis->size, 2);
    ts_ft812_write(address + 12, &axis->sync_start, 2);
    ts_ft812_write(address + 16, &axis->sync_end, 2);
}

zx_status_t ts_ft812_configure_display(const ts_ft812_timing_t *timing) __z88dk_fastcall {
    if (!timing || !valid_axis(&timing->horizontal) || !valid_axis(&timing->vertical) ||
        timing->vertical.size > 2047u || timing->dither > 1u || timing->swizzle > 15u ||
        timing->cspread > 1u || timing->pclk_polarity > 1u)
        return ZX_INVALID_ARGUMENT;

    ts_ft812_set_pclk(0);
    write_axis(TS_FT812_REG_HCYCLE, &timing->horizontal);
    write_axis(TS_FT812_REG_VCYCLE, &timing->vertical);
    ts_ft812_write(TS_FT812_REG_DITHER, &timing->dither, 1);
    ts_ft812_write(TS_FT812_REG_SWIZZLE, &timing->swizzle, 1);
    ts_ft812_write(TS_FT812_REG_CSPREAD, &timing->cspread, 1);
    ts_ft812_write(TS_FT812_REG_PCLK_POL, &timing->pclk_polarity, 1);
    return ZX_OK;
}
