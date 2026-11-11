#include "../internal.h"

zx_status_t zx_sd_read_ocr(uint8_t ocr[4], uint16_t max_polls) {
    zx_sd_transaction_t transaction;
    zx_status_t status;
    if (!ocr || !max_polls) return ZX_INVALID_ARGUMENT;
    status = zx__sd_claim(&transaction, 1);
    if (status != ZX_OK) return status;
    status = zx_sd_wait_ready(&transaction, max_polls);
    if (status == ZX_OK) status = zx__sd_read_ocr_register(&transaction, ocr);
    zx_sd_end(&transaction);
    return status;
}
