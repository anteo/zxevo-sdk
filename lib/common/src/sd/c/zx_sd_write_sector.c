#include "../internal.h"

/* The card responds after the CRC bytes, then holds MISO low while writing. */
static zx_status_t zx__sd_finish_write(zx_sd_transaction_t *transaction, uint16_t max_polls) {
    uint16_t polls = max_polls;
    uint8_t response;
    do {
        zx_sd_receive_previous(transaction, &response);
        if (response != 0xff) {
            zx_status_t status = zx_sd_wait_ready(transaction, max_polls);
            return (response & 0x1fu) == 5 ? status : ZX_IO_ERROR;
        }
    } while (--polls);
    return ZX_TIMEOUT;
}

zx_status_t zx_sd_write_sector(zx_sd_card_type_t type, uint32_t lba, const void *buffer,
                               uint16_t max_polls) {
    zx_sd_transaction_t transaction;
    zx_status_t status;
    if (!buffer || !max_polls) return ZX_INVALID_ARGUMENT;
    status = zx__sd_sector_address(type, &lba);
    if (status != ZX_OK) return status;
    status = zx__sd_claim(&transaction, 1);
    if (status != ZX_OK) return status;
    status = zx_sd_wait_ready(&transaction, max_polls);
    if (status == ZX_OK) status = zx__sd_command_ok(&transaction, 24, lba);
    if (status == ZX_OK) {
        zx_sd_transmit(&transaction, 0xfe);
        zx_sd_write_block(&transaction, buffer);
        zx_sd_transmit(&transaction, 0xff);
        zx_sd_transmit(&transaction, 0xff);
        status = zx__sd_finish_write(&transaction, max_polls);
    }
    zx_sd_end(&transaction);
    return status;
}
