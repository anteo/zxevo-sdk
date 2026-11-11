#include "../internal.h"

zx_status_t zx__ide_validate_range(uint32_t lba, const void *buffer, uint8_t count,
                                   uint16_t max_polls) {
    uint16_t last_byte;
    if (!buffer || !count || count > 127 || !max_polls || lba > 0x0ffffffful)
        return ZX_INVALID_ARGUMENT;
    last_byte = ((uint16_t)count << 9) - 1u;
    if ((uint16_t)buffer > UINT16_MAX - last_byte || lba + count - 1u > 0x0ffffffful)
        return ZX_INVALID_ARGUMENT;
    return ZX_OK;
}
