#include "../internal.h"

zx_status_t zx__sd_read_register(uint8_t command, uint8_t *buffer, uint16_t max_polls) {
    zx_sd_transaction_t transaction;
    uint8_t i, crc;
    zx_status_t status;
    if (!buffer || !max_polls) return ZX_INVALID_ARGUMENT;
    status = zx__sd_claim(&transaction, 1);
    if (status != ZX_OK) return status;
    status = zx_sd_wait_ready(&transaction, max_polls);
    if (status == ZX_OK) status = zx__sd_command_ok(&transaction, command, 0);
    if (status == ZX_OK) status = zx_sd_wait_data(&transaction, max_polls);
    if (status == ZX_OK) {
        for (i = 0; i < 16; ++i) zx_sd_receive_previous(&transaction, &buffer[i]);
        zx_sd_receive_previous(&transaction, &crc);
        zx_sd_receive_previous(&transaction, &crc);
    }
    zx_sd_end(&transaction);
    return status;
}
