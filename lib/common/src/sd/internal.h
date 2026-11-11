#ifndef ZX_SD_INTERNAL_H
#define ZX_SD_INTERNAL_H

#include <zx/sd.h>

/* Only chip select is platform-specific. Once claimed, the transfer stream
 * uses the same xx57 pipeline and transaction layout on both machines. */
extern zx_sd_transaction_t *zx__sd_active_transaction;
/* Platform backend. Claim supplies a valid pointer and an idle SDK bus. */
zx_status_t zx__sd_control_port(uint8_t *high) __z88dk_fastcall;
zx_status_t zx__sd_claim(zx_sd_transaction_t *transaction, uint8_t selected);
void zx__sd_select(const zx_sd_transaction_t *transaction, uint8_t selected);
zx_status_t zx__sd_sector_address(zx_sd_card_type_t type, uint32_t *lba);
zx_status_t zx__sd_command_ok(zx_sd_transaction_t *transaction, uint8_t command, uint32_t argument);
zx_status_t zx__sd_read_register(uint8_t command, uint8_t *buffer, uint16_t max_polls);
zx_status_t zx__sd_read_ocr_register(zx_sd_transaction_t *transaction, uint8_t *ocr);

#endif
