#include "../internal.h"

zx_status_t zx_sd_load(zx_sd_card_info_t *info, uint16_t max_attempts, uint16_t max_polls) {
    zx_sd_card_type_t type;
    zx_status_t status;
    if (!info || !max_attempts || !max_polls) return ZX_INVALID_ARGUMENT;
    status = zx_sd_init(&type, max_attempts);
    if (status == ZX_OK) status = zx__sd_read_register(10, info->cid, max_polls);
    if (status == ZX_OK) status = zx__sd_read_register(9, info->csd, max_polls);
    info->type = status == ZX_OK ? type : ZX_SD_UNKNOWN;
    return status;
}
