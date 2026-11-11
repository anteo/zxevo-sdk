#include "../internal.h"

zx_status_t zx_ide_write_sectors(uint32_t lba, const void *buffer, uint8_t count,
                                 uint16_t max_polls) {
    const uint8_t *sector = buffer;
    zx_status_t status = zx__ide_validate_range(lba, buffer, count, max_polls);
    if (status != ZX_OK) return status;
    while (1) {
        status = zx_ide_write_sector(lba, sector, max_polls);
        if (status != ZX_OK || !--count) return status;
        ++lba;
        sector += 512;
    }
}
