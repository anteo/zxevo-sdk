#include "../internal.h"

zx_status_t zx_sd_read_cid(uint8_t cid[16], uint16_t max_polls) {
    return zx__sd_read_register(10, cid, max_polls);
}
