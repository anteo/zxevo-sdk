#include <arch/z80.h>
#include <baseconf.h>

#include "bc_case.h"

int main(void) {
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ATM_320) == ZX_OK);
        ZX_ASSERT(bc_set_ulaplus_palette(3, 0x9e) == ZX_UNAVAILABLE);
        ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
        ZX_ASSERT(bc_set_ulaplus_palette(64, 0) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(bc_set_ulaplus_palette(3, 0x9e) == ZX_OK);
        ZX_ASSERT(z80_inp(0xff3b) == 0x9e);
        ZX_ASSERT(bc_set_ulaplus_palette(63, 0x31) == ZX_OK);
        ZX_ASSERT(z80_inp(0xff3b) == 0x31);
        bc_set_ulaplus_enabled(1);
        ZX_ASSERT(z80_inp(0xff3b) == 1);
        bc_set_ulaplus_enabled(0);
        ZX_ASSERT(z80_inp(0xff3b) == 0);
        zx_test_step_marker("ulaplus_registers");
    }
    zx_test_finish();
    return 0;
}
