#include <tsconf/zifi32.h>

zx_status_t ts_zifi32_get_version(ts_zifi32_version_t *version, uint16_t max_polls) {
    uint8_t reply[6];
    zx_status_t result;

    if (!version || !max_polls) {
        return ZX_INVALID_ARGUMENT;
    }

    ts_zifi32_issue(0x02, 0, 0);
    result = ts_zifi32_wait_status(TS_ZIFI32_READY, max_polls, 0);
    if (result != ZX_OK) {
        return result;
    }

    ts_zifi32_read_registers(2, reply, sizeof(reply));
    version->api = reply[0];
    version->feature = (uint16_t)reply[1] | ((uint16_t)reply[2] << 8);
    version->major = reply[3];
    version->minor = reply[4];
    version->patch = reply[5];
    return ZX_OK;
}
