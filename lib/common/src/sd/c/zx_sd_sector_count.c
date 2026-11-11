#include <zx/sd.h>
#include <stdlib.h>

zx_status_t zx_sd_sector_count(zx_sd_card_type_t type, const uint8_t csd[16], uint32_t *sectors) {
    uint8_t structure, block_exp, mult_exp;
    uint32_t size;
    if (!csd || !sectors || type > ZX_SD_SDHC) return ZX_INVALID_ARGUMENT;
    if (type == ZX_SD_UNKNOWN) return ZX_NOT_INITIALIZED;
    structure = csd[0] >> 6;
    /* z88dk extract_bits counts from the wire-order MSB. SD field numbering
     * counts from the LSB, so a field ending at bit N starts at 127 - N. */
    if (type == ZX_SD_SDHC) {
        if (structure != 1) return ZX_UNSUPPORTED;
        size = extract_bits((uint8_t *)csd, 58, 22) + 1; /* C_SIZE[69:48] */
        if (size == 0x400000ul) return ZX_UNSUPPORTED; /* 2^32 sectors */
        *sectors = size << 10;
        return ZX_OK;
    }
    if (structure != 0 && type != ZX_SD_MMC) return ZX_UNSUPPORTED;
    size = extract_bits((uint8_t *)csd, 54, 12) + 1; /* C_SIZE[73:62] */
    if (type == ZX_SD_MMC && size == 4096) return ZX_UNSUPPORTED; /* uses EXT_CSD */
    mult_exp = (uint8_t)extract_bits((uint8_t *)csd, 78, 3) + 2; /* C_SIZE_MULT[49:47] */
    block_exp = csd[5] & 0x0f; /* READ_BL_LEN[83:80] */
    if (block_exp < 9 || block_exp > 11) return ZX_UNSUPPORTED;
    *sectors = size << (block_exp + mult_exp - 9);
    return ZX_OK;
}
