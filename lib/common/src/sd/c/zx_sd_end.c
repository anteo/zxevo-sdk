#include <arch/z80.h>
#include "../internal.h"

zx_status_t zx_sd_end(zx_sd_transaction_t *transaction) {
    if (!transaction || zx__sd_active_transaction != transaction || !transaction->active)
        return ZX_INVALID_ARGUMENT;
    zx__sd_select(transaction, 0);
    z80_outp(0x0057, 0xffu);
    transaction->active = 0;
    transaction->transfer_pending = 0;
    zx__sd_active_transaction = 0;
    return ZX_OK;
}
