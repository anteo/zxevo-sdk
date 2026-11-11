#include "../internal.h"

zx_status_t zx_sd_read_sector(zx_sd_card_type_t type, uint32_t lba, void *buffer,
                              uint16_t max_polls) {
    zx_sd_transaction_t transaction;
    uint8_t crc;
    zx_status_t status;
    if (!buffer || !max_polls) return ZX_INVALID_ARGUMENT;
    status = zx__sd_sector_address(type, &lba);
    if (status != ZX_OK) return status;
    status = zx__sd_claim(&transaction, 1);
    if (status != ZX_OK) return status;
    status = zx_sd_wait_ready(&transaction, max_polls);
    if (status == ZX_OK) status = zx__sd_command_ok(&transaction, 17, lba);
    if (status == ZX_OK) status = zx_sd_wait_data(&transaction, max_polls);
    if (status == ZX_OK) {
        zx_sd_read_block(&transaction, buffer);
        zx_sd_receive_previous(&transaction, &crc);
        zx_sd_receive_previous(&transaction, &crc);
    }
    zx_sd_end(&transaction);
    return status;
}
