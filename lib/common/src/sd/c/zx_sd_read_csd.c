#include "../internal.h"

zx_status_t zx_sd_read_csd(uint8_t csd[16], uint16_t max_polls) {
    return zx__sd_read_register(9, csd, max_polls);
}
