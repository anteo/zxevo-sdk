#include <zx/sd.h>
#include <zx_test.h>

int main(void) {
    uint8_t csd[16] = {0};
    uint32_t capacity = 123;

    zx_test_init();
    ZX_ASSERT(zx_sd_sector_count(ZX_SD_UNKNOWN, csd, &capacity) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_sd_sector_count(ZX_SD_SDHC, csd, &capacity) == ZX_UNSUPPORTED);
    ZX_ASSERT(capacity == 123);

    csd[0] = 0x40; /* CSD v2, C_SIZE = 0x10000 (uses bits above the low word). */
    csd[7] = 1;
    ZX_ASSERT(zx_sd_sector_count(ZX_SD_SDHC, csd, &capacity) == ZX_OK && capacity == 0x04000400ul);
    ZX_ASSERT(zx_sd_size(ZX_SD_SDHC, csd, &capacity) == ZX_UNSUPPORTED);
    ZX_ASSERT(capacity == 0x04000400ul);

    csd[0] = 0;
    csd[5] = 9; /* CSD v1, 512-byte blocks, C_SIZE = 3, C_SIZE_MULT = 0. */
    csd[7] = 0;
    csd[8] = 0xc0;
    ZX_ASSERT(zx_sd_size(ZX_SD_SDSC, csd, &capacity) == ZX_OK && capacity == 8192);
    zx_test_step_marker("capacity");
    zx_test_finish();
    return 0;
}
