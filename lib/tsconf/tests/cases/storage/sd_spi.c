#include <zx/sd.h>
#include <zx_test.h>

static uint8_t sector[512];

static uint8_t pattern(uint16_t i) {
    return (uint8_t)(i ^ (i >> 8) ^ 0xa3u);
}

int main(void) {
    zx_sd_transaction_t transaction;
    zx_sd_transaction_t other = {0};
    zx_sd_card_info_t card;
    uint8_t response = 0x69;
    uint16_t i;
    zx_status_t status;

    zx_test_init();
    ZX_ASSERT(zx_sd_begin(0) == ZX_INVALID_ARGUMENT);
    status = zx_sd_begin(&transaction);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;
    ZX_ASSERT(zx_sd_begin(&other) == ZX_BUSY);
    ZX_ASSERT(zx_sd_end(&other) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_sd_receive_previous(&transaction, &response) == ZX_BUSY);
    ZX_ASSERT(response == 0x69);
    ZX_ASSERT(zx_sd_end(&transaction) == ZX_OK);
    ZX_ASSERT(zx_sd_end(&transaction) == ZX_INVALID_ARGUMENT);
    zx_test_step_marker("transaction");

    status = zx_sd_load(&card, 128, 128);
    ZX_ASSERT(status == ZX_OK && card.type == ZX_SD_SDSC);
    zx_test_step_marker("init-cid-csd");
    if (status != ZX_OK) goto finish;

    ZX_ASSERT(zx_sd_read_sector(ZX_SD_UNKNOWN, 0, sector, 128) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_sd_read_sector(card.type, 0x800000ul, sector, 128) == ZX_INVALID_ARGUMENT);
    status = zx_sd_read_sector(card.type, 0, sector, 128);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        ZX_ASSERT(sector[450] == 6 && sector[455] == 8);
        ZX_ASSERT(sector[510] == 0x55 && sector[511] == 0xaa);
    }
    zx_test_step_marker("mbr");

    /* LBA 1 is outside the partition on this disposable image. */
    for (i = 0; i < sizeof(sector); ++i) sector[i] = pattern(i);
    status = zx_sd_write_sector(card.type, 1, sector, 128);
    /* ZEsarUX can leave the CMD24 acceptance byte on MISO indefinitely.
     * A timeout must still release the bus. Verify the actual sector either way. */
    ZX_ASSERT(status == ZX_OK || status == ZX_TIMEOUT);
    for (i = 0; i < sizeof(sector); ++i) sector[i] = 0;
    status = zx_sd_read_sector(card.type, 1, sector, 128);
    ZX_ASSERT(status == ZX_OK);
    if (status == ZX_OK) {
        for (i = 0; i < sizeof(sector); ++i) ZX_ASSERT(sector[i] == pattern(i));
    }
    zx_test_step_marker("sector-roundtrip");

finish:
    zx_test_finish();
    return 0;
}
