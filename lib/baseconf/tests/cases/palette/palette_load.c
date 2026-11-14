#include <arch/z80.h>
#include <intrinsic.h>
#include <baseconf.h>
#include "bc_case.h"

static const uint8_t colors[16] = {0x00, 0x01, 0x02, 0x03, 0x04, 0x08, 0x0c, 0x10,
                                   0x20, 0x30, 0x15, 0x2a, 0x3f, 0x36, 0x1b, 0x2d};
/* Fixed FF-port RGB222 values, ignoring its two reserved/FDD bits. */
static const uint8_t encoded[16] = {0xf3, 0xd3, 0xf2, 0xd2, 0x73, 0xe3, 0x63, 0xb3,
                                    0xf1, 0xb1, 0x13, 0xe0, 0x00, 0x30, 0x82, 0x41};
static uint8_t read_colors[16];

/* Test-only hardware probes are implemented in palette_load_helpers.asm. */
void frame_irq_on(void);
uint8_t iff_enabled(void);
void sample_border_colors(uint8_t *output) __z88dk_fastcall;

int main(void) {
    bc_surface_t surface = bc_screen_surface(BC_VIDEO_ATM_320, ZX_SCREEN_1);
    bc_window_lease_t lease;
    bc_window_config_t config;
    bc_video_output_t output;
    uint8_t bf, system, border, i;
    uint8_t invalid[16] = {0};
    if (bc_case_init() == ZX_OK) {
        ZX_ASSERT(bc_palette_load_rgb222(colors) == ZX_UNSAFE_CONTEXT);
        frame_irq_on();
        ZX_ASSERT(bc_palette_load_rgb222(0) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(bc_palette_load_rgb222((const uint8_t *)0xfff8) == ZX_INVALID_ARGUMENT);
        invalid[15] = 64;
        ZX_ASSERT(bc_palette_load_rgb222(invalid) == ZX_INVALID_ARGUMENT);
        ZX_ASSERT(bc_palette_load_rgb222(colors) == ZX_UNSAFE_CONTEXT); /* AVR unknown */
        ZX_ASSERT(zx_avr_window_select(ZX_AVR_WINDOW_VERSION) == ZX_OK);
        ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_2, surface.page0) == ZX_OK);
        ZX_ASSERT(bc_map_ram_page(ZX_WINDOW_3, surface.page1) == ZX_OK);
        ZX_ASSERT(bc_select_draw_surface(&surface) == ZX_OK);
        ZX_ASSERT(zx_graphics_begin() == ZX_OK);
        ZX_ASSERT(bc_palette_load_rgb222(colors) == ZX_BUSY);
        ZX_ASSERT(zx_graphics_end() == ZX_OK);
        ZX_ASSERT(bc_get_window_config(bc_get_active_map(), ZX_WINDOW_3, &config) == ZX_OK);
        ZX_ASSERT(bc_window_acquire(ZX_WINDOW_3, config, &lease) == ZX_OK);
        ZX_ASSERT(bc_palette_load_rgb222(colors) == ZX_BUSY);
        ZX_ASSERT(bc_window_release(&lease) == ZX_OK);
        bc_newirq_configure(1, 0);
        ZX_ASSERT(bc_palette_load_rgb222(colors) == ZX_UNSAFE_CONTEXT);
        bc_newirq_configure(0, 0);
        ZX_ASSERT(iff_enabled());
        intrinsic_di();
        zx_test_step_marker("guards");
        frame_irq_on();
        ZX_ASSERT(bc_read_video_output(&output) == ZX_OK);
        bf = z80_inp(0x00bf);
        system = bc_readback_register(0x0c);
        border = bc_readback_register(0x0f);
        if (output.raster >= BC_RASTER_48K) {
            ZX_ASSERT(bc_palette_load_rgb222(colors) == ZX_UNSUPPORTED);
            ZX_ASSERT(z80_inp(0x00bf) == bf && bc_readback_register(0x0c) == system);
            ZX_ASSERT(bc_readback_register(0x0f) == border && iff_enabled());
            intrinsic_di();
            zx_test_step_marker("synchronized-raster-rejected");
            zx_test_step_skip(
                "frame-load-readback",
                "requires Pentagon/60Hz raster; emulator default is synchronized 128K");
        } else {
            bc_set_atm_rgb444_enabled(1);
            ZX_ASSERT(bc_palette_load_rgb222(colors) == ZX_UNAVAILABLE);
            bc_set_atm_rgb444_enabled(0);
            bf = z80_inp(0x00bf);
            ZX_ASSERT(bc_palette_load_rgb222(colors) == ZX_OK);
            ZX_ASSERT(iff_enabled());
            ZX_ASSERT(z80_inp(0x00bf) == bf && bc_readback_register(0x0c) == system);
            ZX_ASSERT(bc_readback_register(0x0f) == border);
            sample_border_colors(read_colors);
            zx_set_border_color(border);
            for (i = 0; i < 16; ++i) ZX_ASSERT(read_colors[i] == encoded[i]);
            intrinsic_di();
            zx_test_step_marker("frame-load-readback");
        }
    }
    zx_test_finish();
    return 0;
}
