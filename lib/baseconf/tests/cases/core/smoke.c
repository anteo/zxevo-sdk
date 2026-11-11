/*
 * Framework smoke test.
 *
 * This is not a coverage test: it exists so that the runner, the direct loader,
 * the ZXHost step protocol and the screenshot/data comparison channels can be
 * exercised with one small case. Real tests live next to it
 * and follow the same structure.
 */
#include <baseconf.h>
#include <graphics.h>
#include <zx/graphics.h>

#include "bc_case.h"

static const bc_surface_t surfaces[] = {
    {BC_VIDEO_ZX_256, 5, 5},      {BC_VIDEO_ZX_MULTICOLOR, 5, 5}, {BC_VIDEO_PENTAGON_256, 4, 5},
    {BC_VIDEO_ATM_320, 1, 5},     {BC_VIDEO_ATM_640, 1, 5},       {BC_VIDEO_ATM_TEXT_80, 1, 5},
    {BC_VIDEO_EVO_TEXT_80, 8, 8},
};

int main(void) {
    zx_status_t status;
    if (bc_case_init() != ZX_OK) {
        zx_test_finish();
        return 0;
    }
    ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
    status = bc_set_video_mode(BC_VIDEO_ZX_256);
    if (status == ZX_OK) {
        zx_set_ink(6);
        zx_set_paper(0);
        clg();
        zx_draw_line(0, 0, 255, 191);
        zx_draw_line(0, 191, 255, 0);
        zx_draw_line(0, 96, 255, 96);
        zx_test_step_shot("zx256");

        zx_test_step_marker("mode");
    } else {
        zx_test_step_skip("zx256", "video mode unavailable");
        zx_test_step_skip("text", "video mode unavailable");
    }
    status = bc_set_video_mode(BC_VIDEO_ATM_640);
    if (status == ZX_OK) {
        zx_set_ink(6);
        zx_set_paper(0);
        clg();
        zx_draw_line(0, 0, 639, 199);
        zx_draw_line(0, 199, 639, 0);
        zx_test_step_shot("atm640");
    } else {
        zx_test_step_skip("atm640", "video mode unavailable");
    }
    /* The table is in rodata, which stays mapped for the whole run. */
    zx_test_step_data(NULL, surfaces, sizeof(surfaces));
    zx_test_finish();
    return 0;
}
