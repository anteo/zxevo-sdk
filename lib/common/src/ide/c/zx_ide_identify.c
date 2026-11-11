#include "../internal.h"

zx_status_t zx_ide_identify(void *buffer, uint16_t max_polls) {
    zx_status_t status;
    if (!buffer) return ZX_INVALID_ARGUMENT;
    status = zx__ide_command(0xec, max_polls);
    if (status != ZX_OK) return status;
    status = zx_ide_wait_data(max_polls);
    if (status != ZX_OK) return status;
    zx_ide_read_block(0x10, 0x80f0, buffer);
    return zx_ide_wait_complete(max_polls);
}
