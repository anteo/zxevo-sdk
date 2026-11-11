#include "../internal.h"

zx_status_t zx__sd_claim(zx_sd_transaction_t *transaction, uint8_t selected) {
    zx_status_t status;
    if (!transaction) return ZX_INVALID_ARGUMENT;
    if (zx__sd_active_transaction) return ZX_BUSY;
    status = zx__sd_control_port(&transaction->control_port_high);
    if (status != ZX_OK) return status;
    transaction->active = 1;
    transaction->transfer_pending = 0;
    zx__sd_active_transaction = transaction;
    zx__sd_select(transaction, selected);
    return ZX_OK;
}
