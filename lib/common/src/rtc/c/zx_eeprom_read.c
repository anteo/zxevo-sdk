#include "../internal.h"

zx_status_t zx_eeprom_read(uint16_t offset, uint8_t *buffer, uint8_t length) {
    return zx__eeprom_transfer(offset, buffer, length, 0);
}
