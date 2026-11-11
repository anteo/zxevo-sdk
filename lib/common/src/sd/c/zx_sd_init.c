#include "../internal.h"

/* CMD55 can be illegal on MMC. CMD1 is only used for legacy cards that reject
 * the SD application-command sequence. */
static zx_status_t zx__sd_init_negotiate(zx_sd_transaction_t *transaction, uint8_t sd_v2,
                                         uint16_t attempts, zx_sd_card_type_t *type) {
    uint8_t r1 = 0xff, mmc = 0;
    zx_status_t status;
    do {
        if (!mmc) {
            status = zx_sd_command(transaction, 55, 0, &r1);
            if (status != ZX_OK) return status;
            if (r1 <= 1) {
                status = zx_sd_command(transaction, 41, sd_v2 ? 0x40000000ul : 0, &r1);
                if (status != ZX_OK) return status;
            }
            if (!sd_v2 && r1 == 5) mmc = 1;
        }
        if (mmc) {
            status = zx_sd_command(transaction, 1, 0, &r1);
            if (status != ZX_OK) return status;
        }
        if (r1 == 0) {
            *type = mmc ? ZX_SD_MMC : ZX_SD_SDSC;
            return ZX_OK;
        }
        if (r1 != 1) return ZX_IO_ERROR;
    } while (--attempts);
    return ZX_TIMEOUT;
}

static zx_status_t zx__sd_init_card(zx_sd_transaction_t *transaction, uint16_t attempts,
                                    zx_sd_card_type_t *type) {
    uint16_t reset_attempts = attempts;
    uint8_t r1, i, sd_v2;
    uint8_t response[4];
    zx_status_t status;

    /* Clock at least 74 cycles with CS high and MOSI high before CMD0. */
    for (i = 0; i < 10; ++i) zx_sd_transmit(transaction, 0xff);
    zx__sd_select(transaction, 1);
    do {
        status = zx_sd_command(transaction, 0, 0, &r1);
        if (status == ZX_OK && r1 == 1) break;
    } while (--reset_attempts);
    if (!reset_attempts) return status == ZX_OK ? ZX_IO_ERROR : status;

    status = zx_sd_command(transaction, 8, 0x1aa, &r1);
    if (status != ZX_OK) return status;
    if (r1 != 1 && r1 != 5) return ZX_IO_ERROR;
    sd_v2 = r1 == 1;
    if (sd_v2) {
        for (i = 0; i < 4; ++i) zx_sd_receive_previous(transaction, &response[i]);
        if ((response[2] & 0x0f) != 1 || response[3] != 0xaa) return ZX_UNSUPPORTED;
    }

    status = zx__sd_init_negotiate(transaction, sd_v2, attempts, type);
    if (status != ZX_OK) return status;
    if (*type != ZX_SD_MMC) {
        status = zx__sd_read_ocr_register(transaction, response);
        if (status != ZX_OK) return status;
        if (!(response[0] & 0x80u) || !(response[1] & 0x30u)) return ZX_UNSUPPORTED;
        if (sd_v2 && (response[0] & 0x40u)) {
            *type = ZX_SD_SDHC;
            return ZX_OK;
        }
    }
    return zx__sd_command_ok(transaction, 16, 512);
}

zx_status_t zx_sd_init(zx_sd_card_type_t *type, uint16_t max_attempts) {
    zx_sd_transaction_t transaction;
    zx_sd_card_type_t detected;
    zx_status_t status;
    if (!type || !max_attempts) return ZX_INVALID_ARGUMENT;
    status = zx__sd_claim(&transaction, 0);
    if (status != ZX_OK) return status;
    status = zx__sd_init_card(&transaction, max_attempts, &detected);
    zx_sd_end(&transaction);
    *type = status == ZX_OK ? detected : ZX_SD_UNKNOWN;
    return status;
}
