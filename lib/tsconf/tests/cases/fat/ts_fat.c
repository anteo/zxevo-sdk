#include <string.h>
#include <tsconf.h>
#include <zx_test.h>

#define DATA_PAGE 0x60u
#define CALLER_PAGE 0x61u
#define FIRST_OFFSET 0x0122u
#define LAST_OFFSET 0x3e00u
#define FILE_LENGTH 777u

static const ts_fat_name_t missing = {TS_FAT_FILE, "MISSING.BIN"};
static const ts_fat_name_t present = {TS_FAT_FILE, "HELLO.BIN"};
static const ts_fat_name_t nested = {TS_FAT_DIRECTORY, "NEST"};
static const ts_fat_name_t parent = {TS_FAT_DIRECTORY, ".."};
static const ts_fat_name_t inner = {TS_FAT_FILE, "INNER.BIN"};
static uint8_t *const w2 = (uint8_t *)0x8000;

static void check_sector(uint16_t destination, uint16_t file_offset) {
    volatile const uint8_t *buffer = w2 + destination;
    uint16_t i;

    ts_fat_read_sector(DATA_PAGE, destination);
    ZX_ASSERT(ts_memory_get_page2() == CALLER_PAGE);

    ts_map_ram_page(ZX_WINDOW_2, DATA_PAGE);
    ZX_ASSERT(buffer[-1] == 0xa5);
    for (i = 0; i < TS_FAT_SECTOR_SIZE; ++i) {
        uint16_t pos = file_offset + i;
        uint8_t expected = pos < FILE_LENGTH ? (uint8_t)(37u * pos + (pos >> 3) + 0x23u) : 0;
        ZX_ASSERT(buffer[i] == expected);
    }
    if (destination == FIRST_OFFSET) {
        ZX_ASSERT(buffer[TS_FAT_SECTOR_SIZE] == 0xa5);
    }
    ts_map_ram_page(ZX_WINDOW_2, CALLER_PAGE);
}

int main(void) {
    uint32_t size = 0x89abcdefUL;
    zx_status_t status;

    zx_test_init();
    ts_map_ram_page(ZX_WINDOW_2, DATA_PAGE);
    memset(w2 + FIRST_OFFSET - 1, 0xa5, TS_FAT_SECTOR_SIZE + 2);
    memset(w2 + LAST_OFFSET - 1, 0xa5, TS_FAT_SECTOR_SIZE + 1);
    ts_map_ram_page(ZX_WINDOW_2, CALLER_PAGE);

    status = ts_fat_mount_sd();
    ZX_ASSERT(status == ZX_OK);
    ZX_ASSERT(ts_memory_get_page2() == CALLER_PAGE);
    zx_test_step_marker("mount-sd");
    if (status != ZX_OK) {
        goto finish;
    }

    ZX_ASSERT(ts_fat_open(&missing, &size) == ZX_IO_ERROR);
    ZX_ASSERT(size == 0x89abcdefUL);
    ZX_ASSERT(ts_memory_get_page2() == CALLER_PAGE);
    zx_test_step_marker("missing-file");

    status = ts_fat_open(&present, &size);
    ZX_ASSERT(status == ZX_OK);
    ZX_ASSERT(size == FILE_LENGTH);
    ZX_ASSERT(ts_memory_get_page2() == CALLER_PAGE);
    zx_test_step_marker("open-file");
    if (status != ZX_OK) {
        goto finish;
    }

    check_sector(FIRST_OFFSET, 0);
    zx_test_step_marker("first-sector");
    check_sector(LAST_OFFSET, TS_FAT_SECTOR_SIZE);
    zx_test_step_marker("fragmented-next-sector");

    ts_fat_rewind();
    ts_fat_skip_sectors(1);
    check_sector(LAST_OFFSET, TS_FAT_SECTOR_SIZE);
    ts_fat_rewind();
    ts_fat_skip_sectors(0);
    check_sector(FIRST_OFFSET, 0);
    zx_test_step_marker("seek-and-skip");

    status = ts_fat_set_directory(&nested);
    ZX_ASSERT(status == ZX_OK && ts_memory_get_page2() == CALLER_PAGE);
    if (status == ZX_OK) {
        ZX_ASSERT(ts_fat_open(&present, &size) != ZX_OK);
        status = ts_fat_open(&inner, &size);
        ZX_ASSERT(status == ZX_OK && size == TS_FAT_SECTOR_SIZE);
        if (status == ZX_OK) check_sector(FIRST_OFFSET, 0);
        ZX_ASSERT(ts_fat_set_directory(&parent) == ZX_OK);
        ZX_ASSERT(ts_fat_open(&present, &size) == ZX_OK && size == FILE_LENGTH);
    }
    ts_fat_set_root();
    ZX_ASSERT(ts_fat_set_directory(&present) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_fat_open(&inner, &size) != ZX_OK);
    ZX_ASSERT(ts_memory_get_page2() == CALLER_PAGE);
    zx_test_step_marker("directories");

finish:
    zx_test_finish();
    return 0;
}
