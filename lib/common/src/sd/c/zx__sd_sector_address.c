#include "../internal.h"

zx_status_t zx__sd_sector_address(zx_sd_card_type_t type, uint32_t *lba) {
    if (type == ZX_SD_SDHC) return ZX_OK;
    if (type == ZX_SD_UNKNOWN) return ZX_NOT_INITIALIZED;
    if ((type != ZX_SD_MMC && type != ZX_SD_SDSC) || *lba > 0x7ffffful) return ZX_INVALID_ARGUMENT;
    *lba <<= 9;
    return ZX_OK;
}
