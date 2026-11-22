#include "../internal.h"

zx_status_t zx_eeprom_write(uint16_t offset, const uint8_t *buffer, uint8_t length) {
    return zx__eeprom_transfer(offset, (uint8_t *)buffer, length, 1);
}
