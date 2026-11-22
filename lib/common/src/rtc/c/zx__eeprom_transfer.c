#include "../internal.h"

zx_status_t zx__eeprom_transfer(uint16_t offset, uint8_t *buffer, uint8_t length, uint8_t writing) {
    if (offset > 4096u || length > 4096u - offset || (!buffer && length))
        return ZX_INVALID_ARGUMENT;
    while (length--) {
        zx_status_t status = zx__eeprom_transfer_byte(offset++, buffer++, writing);
        if (status != ZX_OK) return status;
    }
    return ZX_OK;
}
