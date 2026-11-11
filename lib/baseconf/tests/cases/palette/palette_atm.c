#include <arch/z80.h>
#include <baseconf.h>
#include <graphics.h>

#include "bc_case.h"

enum { PORT_BF = 0x00bf, RGB444 = 0x20, INDEX = 6 };

int main(void) {
    const bc_rgb222_t rgb222 = {1, 2, 3};
    /* Keep the two low blue bits equal. ZEsarUX reverses A8 and A13
     * for this channel relative to the FPGA. */
    const bc_rgb444_t rgb444 = {13, 6, 11};
    bc_rgb444_t cached;
    uint8_t bf, system, beam;
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_select_screen(ZX_SCREEN_0) == ZX_OK);
        ZX_ASSERT(bc_set_video_mode(BC_VIDEO_ATM_320) == ZX_OK);
        zx_set_paper(INDEX);
        zx_set_border_color(INDEX);
        clg();
        bf = z80_inp(PORT_BF);
        system = bc_readback_register(0x0c);
        bc_set_atm_rgb444_enabled(0);
        ZX_ASSERT(!bc_get_atm_rgb444_enabled());
        ZX_ASSERT(bc_get_atm_palette_rgb444(INDEX, &cached) == ZX_UNAVAILABLE);
        ZX_ASSERT(bc_set_atm_palette_rgb444(INDEX, rgb444) == ZX_UNAVAILABLE);
        ZX_ASSERT(bc_set_atm_palette(16, rgb222) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(bc_set_atm_palette(INDEX, rgb222) == ZX_OK);
        ZX_ASSERT(bc_readback_register(0x0c) == system);
        ZX_ASSERT(z80_inp(PORT_BF) == (uint8_t)(bf & ~RGB444));
        ZX_ASSERT(bc_read_beam_color(&beam) == ZX_OK && beam == z80_inp(0x0dbd));
        zx_test_step_shot("rgb222");

        bc_set_atm_rgb444_enabled(1);
        ZX_ASSERT(bc_get_atm_rgb444_enabled());
        ZX_ASSERT(bc_set_atm_palette(INDEX, rgb222) == ZX_UNAVAILABLE);
        ZX_ASSERT(bc_set_atm_palette_rgb444(INDEX, rgb444) == ZX_OK);
        ZX_ASSERT(bc_get_atm_palette_rgb444(INDEX, &cached) == ZX_OK);
        ZX_ASSERT(cached.r == 13 && cached.g == 6 && cached.b == 11);
        ZX_ASSERT(bc_readback_register(0x0c) == system);
        ZX_ASSERT(z80_inp(PORT_BF) == (uint8_t)(bf | RGB444));
        ZX_ASSERT(bc_read_beam_color(&beam) == ZX_OK && beam == z80_inp(0x0dbd));
        zx_test_step_shot("rgb444");
        bc_set_atm_rgb444_enabled(BC_CONFIG_RGB444(bf));
    }
    zx_test_finish();
    return 0;
}
