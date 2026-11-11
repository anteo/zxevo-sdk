#include <tsconf/zifi32.h>

zx_status_t ts_zifi32_wait_status(uint8_t expected, uint16_t max_polls, uint8_t *status) {
    uint8_t observed;
    zx_status_t result = ZX_TIMEOUT;

    if (!max_polls || (expected != TS_ZIFI32_READY && expected != TS_ZIFI32_RESET &&
                       expected != TS_ZIFI32_DATA_M2S && expected != TS_ZIFI32_DATA_S2M)) {
        return ZX_INVALID_ARGUMENT;
    }

    do {
        ts_zifi32_read_registers(1, &observed, 1);
        if (observed == expected) {
            result = ZX_OK;
            break;
        }
        if (observed >= 0x80u) {
            result = observed == 0xffu ? ZX_UNAVAILABLE : ZX_IO_ERROR;
            break;
        }
    } while (--max_polls);

    if (status) {
        *status = observed;
    }
    return result;
}
