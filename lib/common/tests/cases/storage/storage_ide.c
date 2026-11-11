#include <string.h>
#include <zx/ide.h>
#include <zx_test.h>

enum { ATA_WORD = 0x8010, ATA_POLLS = 1024 };
static uint8_t sector[512];

static void check_block(void) {
    zx_ata_info_t info;
    uint16_t i;
    zx_status_t status;
    status = zx_ide_get_info(&info, sector, ATA_POLLS);
    ZX_ASSERT(status == ZX_OK && info.lba28_sectors > 8 && info.model[0]);
    ZX_ASSERT(zx_ide_read_sector(0, sector, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_ide_read_sector(0x10000000ul, sector, ATA_POLLS) == ZX_INVALID_ARGUMENT);
    memset(sector, 0xff, sizeof(sector));
    status = zx_ide_read_sector(0, sector, ATA_POLLS);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(sector[450] == 0x0c && sector[455] == 8);
    ZX_ASSERT(sector[510] == 0x55 && sector[511] == 0xaa);
    zx_test_step_marker("read_mbr");

    /* LBA 1 is outside the MBR and the partition, on a disposable image. */
    for (i = 0; i < sizeof(sector); ++i) sector[i] = (uint8_t)(i ^ (i >> 8) ^ 0xa5u);
    status = zx_ide_write_sectors(1, sector, 1, ATA_POLLS);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    memset(sector, 0, sizeof(sector));
    status = zx_ide_read_sectors(1, sector, 1, ATA_POLLS);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    for (i = 0; i < sizeof(sector); ++i) ZX_ASSERT(sector[i] == (uint8_t)(i ^ (i >> 8) ^ 0xa5u));
    zx_test_step_marker("block_roundtrip");
}

static void check_words(void) {
    uint16_t i, word;
    zx_ata_status_t ata;
    zx_status_t status = zx_ide_start_sector(ZX_ATA_WRITE, 1, ATA_POLLS);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    ZX_ASSERT(zx_ide_status(0, &ata) == ZX_OK);
    ZX_ASSERT((ata.value & (ZX_ATA_BUSY | ZX_ATA_DRQ | ZX_ATA_ERROR)) == ZX_ATA_DRQ);
    for (i = 0; i < 256; ++i)
        ZX_ASSERT(zx_ide_write_word(ATA_WORD, (uint16_t)(0xa500u | i)) == ZX_OK);
    ZX_ASSERT(zx_ide_wait_complete(ATA_POLLS) == ZX_OK);
    status = zx_ide_start_sector(ZX_ATA_READ, 1, ATA_POLLS);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) return;
    for (i = 0; i < 256; ++i) {
        ZX_ASSERT(zx_ide_read_word(ATA_WORD, &word) == ZX_OK);
        ZX_ASSERT(word == (uint16_t)(0xa500u | i));
    }
    ZX_ASSERT(zx_ide_wait_complete(ATA_POLLS) == ZX_OK);
    zx_test_step_marker("word_roundtrip");
}

int main(void) {
    zx_test_init();
    check_block();
    check_words();
    zx_test_finish();
    return 0;
}
