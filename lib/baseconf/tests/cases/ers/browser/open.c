#include <baseconf.h>

#include "bc_case.h"

int main(void) {
    if (bc_case_init() == ZX_OK) {
        bc_ers_set_profile(BC_ERS_SERVICES_ROM);
        ZX_ASSERT(bc_ers_cmos_init() == ZX_OK);
        ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);

        ZX_ASSERT(bc_ers_nmi_file_browser_lock(1) == ZX_OK);
        zx_test_step_marker("nmi_locked");
        ZX_ASSERT(bc_ers_nmi_file_browser_lock(0) == ZX_OK);
        zx_test_step_marker("nmi_unlocked");
    }
    zx_test_finish();
    return 0;
}
