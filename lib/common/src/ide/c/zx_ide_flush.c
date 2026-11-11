#include "../internal.h"

zx_status_t zx_ide_flush(uint16_t max_polls) {
    zx_status_t status = zx__ide_command(0xe7, max_polls);
    if (status != ZX_OK) return status;
    return zx_ide_wait_complete(max_polls);
}
