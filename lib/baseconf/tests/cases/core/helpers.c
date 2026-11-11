/* BaseConf paging and configuration bitfield macros. */
#include <baseconf.h>

#include "bc_case.h"

int main(void) {
    if (bc_case_init() != ZX_OK) {
        ZX_ASSERT(0);
        zx_test_finish();
        return 0;
    }

    ZX_ASSERT(BC_PAGING_ACTIVE_MAP(0x10u) == BC_MAP_1);
    ZX_ASSERT(BC_PAGING_SCREEN(0x08u) == ZX_SCREEN_1);
    ZX_ASSERT(BC_PAGING_RAM_PAGE_1024K(0xe7u) == 0x3fu);
    ZX_ASSERT(BC_CONFIG_SHADOW_PORTS(0x07u) == 1u);
    ZX_ASSERT(BC_CONFIG_FLASH_WRITE(0x07u) == 1u);
    ZX_ASSERT(BC_CONFIG_FONT_WRITE(0x07u) == 1u);
    ZX_ASSERT(BC_CONFIG_RGB444(0x20u) == 1u);

    zx_test_finish();
    return 0;
}
