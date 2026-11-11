#include "../internal.h"

zx_status_t zx__sd_read_ocr_register(zx_sd_transaction_t *transaction, uint8_t *ocr) {
    uint8_t i;
    zx_status_t status = zx__sd_command_ok(transaction, 58, 0);
    if (status != ZX_OK) return status;
    for (i = 0; i < 4; ++i) zx_sd_receive_previous(transaction, &ocr[i]);
    return ZX_OK;
}
