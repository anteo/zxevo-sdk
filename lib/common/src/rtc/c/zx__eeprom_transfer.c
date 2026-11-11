#include "../internal.h"

static zx_status_t transfer(uint16_t offset, uint8_t *buffer, uint8_t length, uint8_t writing) {
    if (offset > 4096u || length > 4096u - offset || (!buffer && length))
        return ZX_INVALID_ARGUMENT;
    while (length--) {
        zx_status_t status = zx__eeprom_transfer_byte(offset++, buffer++, writing);
        if (status != ZX_OK) return status;
    }
    return ZX_OK;
}

zx_status_t zx_eeprom_read(uint16_t offset, uint8_t *buffer, uint8_t length) {
    return transfer(offset, buffer, length, 0);
}

zx_status_t zx_eeprom_write(uint16_t offset, const uint8_t *buffer, uint8_t length) {
    return transfer(offset, (uint8_t *)buffer, length, 1);
}
