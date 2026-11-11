#include "../internal.h"

zx_status_t zx__sd_command_ok(zx_sd_transaction_t *transaction, uint8_t command,
                              uint32_t argument) {
    uint8_t r1;
    zx_status_t status = zx_sd_command(transaction, command, argument, &r1);
    if (status != ZX_OK) return status;
    return r1 == 0 ? ZX_OK : ZX_IO_ERROR;
}
