#include <baseconf.h>

#include "bc_case.h"

int main(void) {
    uint8_t index = 0xff;
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ZX_256) == ZX_OK);
        ZX_ASSERT(zx_graphics_begin() == ZX_UNSUPPORTED);
        ZX_ASSERT(zx_read_pixel_index(0, 0, &index) == ZX_UNSUPPORTED);
        ZX_ASSERT(index == 0xff);
        ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
        zx_test_step_marker("disabled");
    }
    zx_test_finish();
    return 0;
}
