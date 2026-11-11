#include "../internal.h"

static uint8_t to_bcd(uint8_t value) {
    uint8_t tens = 0;

    while (value >= 10u) {
        value -= 10u;
        tens += 0x10u;
    }
    return tens | value;
}

static uint8_t to_binary(uint8_t value) {
    uint8_t tens = value >> 4;
    return (uint8_t)((tens << 3) + (tens << 1) + (value & 0x0fu));
}

zx_status_t zx_rtc_read_datetime(zx_datetime_t *datetime, zx_rtc_format_t format) {
    static const uint8_t indices[] = {ZX_RTC_SECONDS, ZX_RTC_MINUTES, ZX_RTC_HOURS, ZX_RTC_WEEKDAY,
                                      ZX_RTC_DAY,     ZX_RTC_MONTH,   ZX_RTC_YEAR};
    zx_datetime_t sample;
    uint8_t *fields = (uint8_t *)&sample;
    uint16_t scope;
    uint8_t control, attempt, i;

    if (!datetime || format > ZX_RTC_BCD) return ZX_INVALID_ARGUMENT;
    for (attempt = 0; attempt < 3u; ++attempt) {
        scope = zx__rtc_scope_begin();
        control = zx__rtc_read_scoped(ZX_RTC_CONTROL_B);
        if (control == 0xffu) {
            zx__rtc_scope_end(scope);
            return ZX_UNAVAILABLE;
        }
        for (i = 0; i < sizeof(indices); ++i) fields[i] = zx__rtc_read_scoped(indices[i]);
        i = zx__rtc_read_scoped(ZX_RTC_SECONDS);
        zx__rtc_scope_end(scope);
        if (sample.second == i) break;
    }
    if (attempt == 3u) return ZX_TIMEOUT;

    if (control & ZX__RTC_BINARY) {
        if (format == ZX_RTC_BCD)
            for (i = 0; i < sizeof(indices); ++i) fields[i] = to_bcd(fields[i]);
    } else if (format == ZX_RTC_BINARY) {
        for (i = 0; i < sizeof(indices); ++i) fields[i] = to_binary(fields[i]);
    }
    *datetime = sample;
    return ZX_OK;
}
