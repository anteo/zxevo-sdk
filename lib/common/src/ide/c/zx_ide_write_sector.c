#include "../internal.h"

zx_status_t zx_ide_write_sector(uint32_t lba, const void *buffer, uint16_t max_polls) {
    zx_status_t status;
    if (!buffer) return ZX_INVALID_ARGUMENT;
    status = zx_ide_start_sector(ZX_ATA_WRITE, lba, max_polls);
    if (status != ZX_OK) return status;
    zx_ide_write_block(0x10, 0x80f0, buffer);
    return zx_ide_wait_complete(max_polls);
}
