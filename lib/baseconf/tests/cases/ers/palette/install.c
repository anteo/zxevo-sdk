#include <baseconf.h>
#include <string.h>

#include "bc_case.h"

/* ERS consumes ATM color bytes starting at palette index 15. */
static const uint8_t palette[16] = {
    0x5c, 0x9f, 0x7d, 0xdf, 0xbc, 0x6f, 0xec, 0x1d, 0x8f, 0xdc, 0x2e, 0xac, 0xcd, 0x3e, 0xfc, 0x4f,
};
static uint8_t colors[16];

int main(void) {
    uint8_t *const bitmap = (uint8_t *)0xc000u;
    uint8_t *attributes = (uint8_t *)0xd800u;
    bc_window_config_t screen = {BC_RAM, 5, 0, 0};
    bc_window_lease_t lease;
    zx_status_t status;
    uint8_t index;
    uint8_t row;

    if (bc_case_init() != ZX_OK) goto finish;
    bc_ers_set_profile(BC_ERS_SERVICES_ROM);
    status = bc_ers_set_palette(palette);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;

    status = bc_set_video_mode(BC_VIDEO_ZX_256);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;
    status = bc_select_screen(ZX_SCREEN_0);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;
    status = bc_window_acquire(ZX_WINDOW_3, screen, &lease);
    ZX_ASSERT(status == ZX_OK);
    if (status != ZX_OK) goto finish;

    /* Use the same paper and border index so readback is independent of beam position. */
    memset(bitmap, 0, 6144u);
    for (index = 0; index < sizeof(colors); ++index) {
        memset(attributes, index << 3, 768u);
        zx_set_border_color(index);
        ZX_ASSERT(bc_read_beam_color(&colors[index]) == ZX_OK);
    }

    /* Draw the sixteen palette entries from left to right, two cells per color. */
    for (row = 0; row < 24u; ++row) {
        for (index = 0; index < sizeof(colors); ++index) {
            *attributes++ = (uint8_t)(index << 3);
            *attributes++ = (uint8_t)(index << 3);
        }
    }
    zx_set_border_color(9); /* Gray in the test palette. */
    ZX_ASSERT(bc_window_release(&lease) == ZX_OK);
    zx_test_step_data("readback", colors, sizeof(colors));
    zx_test_step_shot("swatches");

finish:
    zx_test_finish();
    return 0;
}
