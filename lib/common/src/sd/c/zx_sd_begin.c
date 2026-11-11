#include "../internal.h"

zx_status_t zx_sd_begin(zx_sd_transaction_t *transaction) {
    return zx__sd_claim(transaction, 1);
}
