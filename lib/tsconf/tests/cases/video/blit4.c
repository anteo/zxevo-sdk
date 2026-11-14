#include <tsconf.h>
#include <zx_test.h>
#define SCREEN_WIDTH 512
#define SCREEN_HEIGHT 512
#include "../../../../common/tests/support/blit4_checks.h"
int main(void) {
    const ts_surface_t surface = {TS_VIDEO_16C, 0x50, 0};
    const ts_surface_t other = {TS_VIDEO_256C, 0x40, 0};
    ts_window_lease_t lease;
    zx_bitmap4_t unsafe = image4;
    volatile uint8_t *const w3 = (volatile uint8_t *)0xc000;
    zx_test_init();
    ZX_ASSERT(zx_blit4(&image4, 0, 0) == ZX_NOT_INITIALIZED);
    ZX_ASSERT(ts_video_select_draw_surface(&surface) == ZX_OK);
    ts_map_ram_page(ZX_WINDOW_3, 0x7e);
    w3[0] = 0x69;
    check_blit_pixels();
    check_blit_arguments();
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && w3[0] == 0x69);
    /* Row 63 -> 64 requires switching the physical destination page. */
    ZX_ASSERT(zx_blit4(&image4, 2, 63) == ZX_OK);
    expect_pixel(2, 63, 0);
    expect_pixel(2, 64, 8);
    expect_pixel(2, 65, 13);
    ts_map_ram_page(ZX_WINDOW_3, 0x50);
    ZX_ASSERT(w3[63 * 256 + 1] == 0x01);
    ts_map_ram_page(ZX_WINDOW_3, 0x51);
    ZX_ASSERT(w3[1] == 0x89);
    ts_map_ram_page(ZX_WINDOW_3, 0x7e);
    ZX_ASSERT(zx_graphics_begin() == ZX_OK);
    ZX_ASSERT(zx_blit4(&image4, 0, 30) == ZX_OK);
    ZX_ASSERT(zx_graphics_end() == ZX_OK && ts_memory_get_page3() == 0x7e);
    ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
    ZX_ASSERT(ts_window_acquire(ZX_WINDOW_3, 0x7d, &lease) == ZX_OK);
    ZX_ASSERT(zx_blit4(&image4, 0, 0) == ZX_BUSY);
    ZX_ASSERT(ts_window_release(&lease) == ZX_OK);
    unsafe.pixels = (const uint8_t *)0xbfff;
    ZX_ASSERT(zx_blit4(&unsafe, 0, 0) == ZX_UNSAFE_CONTEXT);
    ZX_ASSERT(ts_video_select_draw_surface(&other) == ZX_OK);
    ZX_ASSERT(zx_blit4(&image4, 0, 0) == ZX_UNSUPPORTED);
    zx_test_step_marker("pages-and-leases");
    zx_test_finish();
    return 0;
}
