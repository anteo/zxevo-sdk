#include <tsconf/fat.h>
#include <tsconf/io.h>
#include <tsconf/memory.h>
#include <zx/interrupt.h>
#include <zx_test.h>

#define DATA_PAGE 0x60u
#define CALLER_PAGE 0x61u
#define OFFSET 0x0122u

static const ts_fat_name_t folder = {TS_FAT_DIRECTORY, "MADE"};
static const ts_fat_name_t file = {TS_FAT_FILE, "NEW.BIN"};
static volatile uint8_t *const buffer = (volatile uint8_t *)(0x8000u + OFFSET);

static uint8_t pattern(uint16_t i) {
    return (uint8_t)(i ^ (i >> 8) ^ 0x6du);
}

int main(void) {
    uint32_t size = 0;
    uint16_t i;
    zx_status_t status;

    zx_test_init();
    zx_interrupt_enable(0);
    ts_memory_set_page2(CALLER_PAGE);
    ts_io_set_interrupt_mask(1);
    ZX_ASSERT(ts_fat_mount_ide(2) == ZX_INVALID_ARGUMENT);
    status = ts_fat_mount_ide(TS_FAT_IDE_MASTER);
    ZX_ASSERT(status == ZX_OK && ts_memory_get_page2() == CALLER_PAGE);
    zx_test_step_marker("mount-nemo");
    if (status != ZX_OK) goto finish;

    status = ts_fat_create_directory(folder.name);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;
    status = ts_fat_set_directory(&folder);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;
    ZX_ASSERT(ts_fat_create_file(&folder, TS_FAT_SECTOR_SIZE) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_fat_create_file(&file, 0) == ZX_INVALID_ARGUMENT);
    status = ts_fat_create_file(&file, TS_FAT_SECTOR_SIZE);
    ZX_ASSERT(status == ZX_OK && ts_memory_get_page2() == CALLER_PAGE);
    zx_test_step_marker("create-file");
    if (status != ZX_OK) goto finish;

    ts_memory_set_page2(DATA_PAGE);
    for (i = 0; i < TS_FAT_SECTOR_SIZE; ++i) buffer[i] = pattern(i);
    ts_memory_set_page2(CALLER_PAGE);
    ts_fat_write_sector(DATA_PAGE, OFFSET);
    ZX_ASSERT(ts_memory_get_page2() == CALLER_PAGE);

    ts_memory_set_page2(DATA_PAGE);
    for (i = 0; i < TS_FAT_SECTOR_SIZE; ++i) buffer[i] = 0;
    ts_memory_set_page2(CALLER_PAGE);
    status = ts_fat_open(&file, &size);
    ZX_ASSERT(status == ZX_OK && size == TS_FAT_SECTOR_SIZE);
    if (status != ZX_OK) goto finish;
    ts_fat_read_sector(DATA_PAGE, OFFSET);
    ZX_ASSERT(ts_memory_get_page2() == CALLER_PAGE);
    ts_memory_set_page2(DATA_PAGE);
    for (i = 0; i < TS_FAT_SECTOR_SIZE; ++i) ZX_ASSERT(buffer[i] == pattern(i));
    ts_memory_set_page2(CALLER_PAGE);
    zx_test_step_marker("write-read-roundtrip");

    ZX_ASSERT(ts_fat_delete_file(&folder) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_fat_delete_file(&file) == ZX_OK);
    ZX_ASSERT(ts_fat_open(&file, &size) == ZX_IO_ERROR);
    ts_fat_set_root();
    ZX_ASSERT(ts_memory_get_page2() == CALLER_PAGE);
    zx_test_step_marker("delete-file");

finish:
    ts_io_set_interrupt_mask(0);
    zx_test_finish();
    return 0;
}
