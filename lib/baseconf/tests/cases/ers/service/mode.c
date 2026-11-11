#include <baseconf.h>

#include "bc_case.h"

static void check_mode(uint8_t request, uint8_t video_turbo, uint8_t slow_clock) {
    uint8_t saved = 0;

    ZX_ASSERT(bc_ers_set_mode(request, &saved) == ZX_OK);
    ZX_ASSERT((bc_readback_register(0x0c) & 0x0fu) == video_turbo);
    ZX_ASSERT((bc_readback_register(0x0b) & 0x10u) == slow_clock);
    ZX_ASSERT(bc_ers_set_mode(0, &saved) == ZX_OK);
    ZX_ASSERT(saved == request);
}

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_ers_set_profile(BC_ERS_SERVICES_ROM);
        check_mode(0x1b, 3, 0x10); /* ZX 256 at 3.5 MHz */
        zx_test_step_marker("zx_256");
        check_mode(0x3f, 0x0f, 0); /* Evolution text at 14 MHz */
        zx_test_step_marker("evo_text");
        check_mode(0x1b, 3, 0x10);
        zx_test_step_marker("restore_zx");
    }
    zx_test_finish();
    return 0;
}
