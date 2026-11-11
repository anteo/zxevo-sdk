#ifndef ZX_SD_H
#define ZX_SD_H

#include <stdint.h>
#include <zx/status.h>

/* Caller-owned SPI state. Keep the same resident address for the lifetime
 * of a transaction opened with zx_sd_begin. */
typedef struct {
    uint8_t active;
    uint8_t control_port_high;
    uint8_t transfer_pending;
} zx_sd_transaction_t;
typedef enum { ZX_SD_UNKNOWN, ZX_SD_MMC, ZX_SD_SDSC, ZX_SD_SDHC } zx_sd_card_type_t;
typedef struct {
    zx_sd_card_type_t type;
    uint8_t cid[16], csd[16];
} zx_sd_card_info_t;

/* Claim the SPI bus and select the SD card (SD1 on TSConf). Serialize
 * with all SPI users, including ROM, DMA and interrupt handlers. BaseConf
 * requires working readback and stable DOS/shadow decoding until zx_sd_end.
 * Returns ZX_INVALID_ARGUMENT for NULL, ZX_BUSY for an active transaction
 * or ZX_UNAVAILABLE if BaseConf readback is absent. */
zx_status_t zx_sd_begin(zx_sd_transaction_t *transaction);
/* Deselect the card, clock one FFh byte with CS high and invalidate the handle.
 * Returns ZX_INVALID_ARGUMENT unless this is the current active transaction. */
zx_status_t zx_sd_end(zx_sd_transaction_t *transaction);
/* Send a command number 0..63 with a big-endian argument and computed CRC7.
 * Store the R1 byte (including any card error bits) and leave the next response
 * byte pending. Returns ZX_TIMEOUT if no R1 arrives. The caller must ensure
 * the card is ready for a new command and provide a non-NULL R1 pointer. */
zx_status_t zx_sd_command(zx_sd_transaction_t *transaction, uint8_t command, uint32_t argument,
                          uint8_t *r1);
/* Wait for the FEh read token. On ZX_OK the first payload byte is pending.
 * Returns ZX_IO_ERROR for an SD data error token or ZX_TIMEOUT on exhaustion. */
zx_status_t zx_sd_wait_data(zx_sd_transaction_t *transaction, uint16_t max_polls);
/* Clock until the card releases busy (FFh). Returns ZX_TIMEOUT on exhaustion.
 * Both waits require a nonzero byte budget and an active transaction. */
zx_status_t zx_sd_wait_ready(zx_sd_transaction_t *transaction, uint16_t max_polls);

/* Initialize an MMC or SD card in SPI mode and detect its addressing type.
 * max_attempts bounds the initialization retries. On failure after claiming
 * the bus, set *type to ZX_SD_UNKNOWN. Release the bus before returning. */
zx_status_t zx_sd_init(zx_sd_card_type_t *type, uint16_t max_attempts);
/* Initialize the card and fetch CID and CSD. Set info->type to ZX_SD_UNKNOWN
 * if initialization or a register read fails. */
zx_status_t zx_sd_load(zx_sd_card_info_t *info, uint16_t max_attempts, uint16_t max_polls);
/* Read or write one 512-byte LBA using the type returned by zx_sd_init.
 * Byte-addressed cards accept LBA 0..0x7fffff. max_polls must be nonzero and
 * bounds token and busy waits. These calls claim and release the bus.
 * A write may reach the card before the final busy wait times out. */
zx_status_t zx_sd_read_sector(zx_sd_card_type_t type, uint32_t lba, void *buffer,
                              uint16_t max_polls);
zx_status_t zx_sd_write_sector(zx_sd_card_type_t type, uint32_t lba, const void *buffer,
                               uint16_t max_polls);
/* Read registers in wire order from an initialized card. max_polls bounds
 * the ready wait and, for CID/CSD, the data-token wait. OCR is SD-only. */
zx_status_t zx_sd_read_cid(uint8_t cid[16], uint16_t max_polls);
zx_status_t zx_sd_read_csd(uint8_t csd[16], uint16_t max_polls);
zx_status_t zx_sd_read_ocr(uint8_t ocr[4], uint16_t max_polls);

/* Decode the number of 512-byte sectors from a legacy or high-capacity CSD.
 * Supply the type returned by zx_sd_init. Returns ZX_UNSUPPORTED when the
 * format or sector count cannot be represented. */
zx_status_t zx_sd_sector_count(zx_sd_card_type_t type, const uint8_t csd[16], uint32_t *sectors);
/* Return the CSD capacity in bytes when it fits in uint32_t. */
zx_status_t zx_sd_size(zx_sd_card_type_t type, const uint8_t csd[16], uint32_t *bytes);
/* Read 512 preceding SPI responses into a non-NULL writable buffer while
 * clocking 512 FFh bytes; the final exchange remains pending. Prime the SPI
 * pipeline first so the first returned byte is the desired data byte.
 * Returns ZX_INVALID_ARGUMENT for NULL buffer or a noncurrent/inactive handle. */
zx_status_t zx_sd_read_block(zx_sd_transaction_t *transaction, void *buffer);
/* Read the preceding SPI response into rx and clock another FFh byte, leaving
 * a response pending again. Returns ZX_BUSY if no transfer is pending, or
 * ZX_INVALID_ARGUMENT for NULL rx or a noncurrent/inactive handle. */
zx_status_t zx_sd_receive_previous(zx_sd_transaction_t *transaction, uint8_t *rx);
/* Clock tx over SD SPI and mark a response pending; does not return received
 * data. Returns ZX_INVALID_ARGUMENT for a noncurrent/inactive handle. */
zx_status_t zx_sd_transmit(zx_sd_transaction_t *transaction, uint8_t tx);
/* Transmit exactly 512 bytes from a non-NULL readable buffer; received bytes
 * are discarded except the final response left pending. Returns
 * ZX_INVALID_ARGUMENT for NULL buffer or a noncurrent/inactive handle. */
zx_status_t zx_sd_write_block(zx_sd_transaction_t *transaction, const void *buffer);

#endif
