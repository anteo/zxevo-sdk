#include "../internal.h"

zx_status_t zx_sd_size(zx_sd_card_type_t type, const uint8_t csd[16], uint32_t *bytes) {
    uint32_t sectors;
    zx_status_t status;
    if (!bytes) return ZX_INVALID_ARGUMENT;
    status = zx_sd_sector_count(type, csd, &sectors);
    if (status != ZX_OK) return status;
    if (sectors > 0x7ffffful) return ZX_UNSUPPORTED;
    *bytes = sectors << 9;
    return ZX_OK;
}
