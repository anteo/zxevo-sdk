#include <tsconf.h>
#include <zx_test.h>

static volatile uint8_t *const w3 = (volatile uint8_t *)0xc000;

static void check_zx(void) {
    const ts_surface_t bitmap = {TS_VIDEO_ZX, 5, w3};
    ts_map_ram_page(ZX_WINDOW_3, 5);
    ZX_ASSERT(ts_video_select_draw_surface(&bitmap) == ZX_OK);
    w3[0] = 0;
    w3[0x100] = 0;
    w3[0x200] = 0;
    w3[0x1800] = 0x46;

    zx_draw_plot_op(0, 0, ZX_DRAW_SET);
    ZX_ASSERT(w3[0] == 0x80);
    zx_draw_plot_xor(0, 0);
    ZX_ASSERT(w3[0] == 0);
    zx_draw_hline(3, 0, 0);
    ZX_ASSERT(w3[0] == 0xf0);
    zx_draw_hline_xor(1, 2, 0);
    ZX_ASSERT(w3[0] == 0x90);
    zx_draw_line_clear(0, 0, 3, 0);
    zx_draw_plot_xor(-1, 0);
    zx_draw_plot_op(0, 0, (zx_draw_op_t)3);
    ZX_ASSERT(w3[0] == 0 && w3[0x1800] == 0x46);
    zx_draw_vline(3, 2, 0);
    ZX_ASSERT(w3[0] == 0x10 && w3[0x100] == 0x10 && w3[0x200] == 0x10);
    zx_draw_vline_xor(3, 2, 1);
    zx_draw_vline_clear(3, 0, 0);
    ZX_ASSERT(w3[0] == 0 && w3[0x100] == 0 && w3[0x200] == 0);
    zx_test_step_marker("zx-bit-ops");
}

static void check_group(void) {
    const ts_surface_t canvas = {TS_VIDEO_16C, 0x50, 0};
    const ts_surface_t other = {TS_VIDEO_256C, 0x40, 0};
    ts_window_lease_t other_lease;
    uint8_t index = 0x69;

    ts_map_ram_page(ZX_WINDOW_3, 0x50);
    w3[0] = 0xab;
    w3[0x3f00] = 0;
    ts_map_ram_page(ZX_WINDOW_3, 0x51);
    w3[0] = 0;
    ts_map_ram_page(ZX_WINDOW_3, 0x7e);
    w3[0] = 0x69;
    ZX_ASSERT(ts_video_select_draw_surface(&canvas) == ZX_OK);
    zx_set_paper(7);

    ZX_ASSERT(ts_window_acquire(ZX_WINDOW_3, 0x7d, &other_lease) == ZX_OK);
    ZX_ASSERT(zx_shutdown() == ZX_BUSY);
    ZX_ASSERT(zx_graphics_begin() == ZX_BUSY);
    ZX_ASSERT(zx_console_putc('A') == ZX_BUSY);
    ZX_ASSERT(zx_console_draw(0, 0, "A") == ZX_BUSY);
    zx_draw_plot(0, 0);
    ZX_ASSERT(zx_read_pixel_index(0, 0, &index) == ZX_BUSY && index == 0x69);
    ZX_ASSERT(ts_memory_get_page3() == 0x7d);
    ZX_ASSERT(ts_window_release(&other_lease) == ZX_OK);

    ZX_ASSERT(zx_graphics_begin() == ZX_OK);
    ZX_ASSERT(zx_graphics_begin() == ZX_OK);
    ZX_ASSERT(zx_shutdown() == ZX_BUSY);
    ZX_ASSERT(ts_video_select_draw_surface(&other) == ZX_BUSY);
    ZX_ASSERT(ts_window_acquire(ZX_WINDOW_3, 0x7d, &other_lease) == ZX_BUSY);
    zx_set_ink(0xf3);
    zx_draw_plot_xor(0, 0);
    ZX_ASSERT(ts_memory_get_page3() == 0x50 && w3[0] == 0x9b);
    zx_draw_plot_clear(1, 0);
    ZX_ASSERT(w3[0] == 0x97);
    zx_set_ink(0x8e);
    zx_draw_line_op(0, 63, 0, 64, ZX_DRAW_XOR);
    ZX_ASSERT(ts_memory_get_page3() == 0x51 && w3[0] == 0xe0);
    ZX_ASSERT(zx_read_pixel_index(0, 63, &index) == ZX_OK && index == 14);
    ZX_ASSERT(ts_memory_get_page3() == 0x50);
    ZX_ASSERT(zx_graphics_end() == ZX_OK && ts_memory_get_page3() == 0x50);
    ZX_ASSERT(zx_graphics_end() == ZX_OK && ts_memory_get_page3() == 0x7e);
    ZX_ASSERT(w3[0] == 0x69);
    ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
    zx_test_step_marker("packed-group");
}

static void check_shapes(void) {
    const ts_surface_t canvas = {TS_VIDEO_256C, 0x40, 0};

    ZX_ASSERT(ts_video_select_draw_surface(&canvas) == ZX_OK);
    ts_map_ram_page(ZX_WINDOW_3, 0x40);
    w3[0] = 0;
    w3[1] = 0xb3;
    w3[3] = 0;
    w3[3 * 512] = 0;
    w3[10 * 512 + 5] = 0;
    w3[10 * 512 + 10] = 0;
    w3[10 * 512 + 15] = 0;
    w3[12 * 512 + 10] = 0;
    w3[10 * 512 + 20] = 0;
    ts_map_ram_page(ZX_WINDOW_3, 0x7e);

    zx_set_ink(0xf0);
    zx_draw_plot_xor(1, 0);
    {
        uint8_t index;
        ZX_ASSERT(zx_read_pixel_index(1, 0, &index) == ZX_OK && index == 0x43);
    }
    zx_set_paper(0xb7);
    zx_draw_plot_clear(1, 0);
    zx_draw_circle_clear(0, 0, 3);
    {
        uint8_t index;
        ZX_ASSERT(zx_read_pixel_index(3, 0, &index) == ZX_OK && index == 0xb7);
    }
    zx_set_ink(9);
    zx_draw_circle(0, 0, 3);
    zx_set_ink(0x41);
    zx_draw_ellipse(10, 10, 5, 2);
    zx_set_ink(0x80);
    zx_draw_ellipse_xor(20, 10, 0, 2);
    zx_set_ink(0xff);
    zx_draw_circle(0, 0, -1);
    zx_draw_circle(32767, 32767, 4);
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && w3[0] == 0x69);
    ts_map_ram_page(ZX_WINDOW_3, 0x40);
    ZX_ASSERT(w3[0] == 0 && w3[1] == 0xb7 && w3[3] == 9 && w3[3 * 512] == 9);
    ZX_ASSERT(w3[10 * 512 + 5] == 0x41 && w3[10 * 512 + 15] == 0x41);
    ZX_ASSERT(w3[12 * 512 + 10] == 0x41 && w3[10 * 512 + 10] == 0);
    ZX_ASSERT(w3[10 * 512 + 20] == 0x80);
    zx_test_step_marker("clipped-shapes");
}

int main(void) {
    zx_test_init();
    ZX_ASSERT(zx_graphics_begin() == ZX_NOT_INITIALIZED);
    ZX_ASSERT(zx_graphics_end() == ZX_NOT_INITIALIZED);
    check_zx();
    check_group();
    check_shapes();
    ZX_ASSERT(zx_shutdown() == ZX_OK);
    ZX_ASSERT(zx_shutdown() == ZX_OK);
    ZX_ASSERT(zx_graphics_begin() == ZX_NOT_INITIALIZED);
    ZX_ASSERT(ts_memory_get_page3() == 0x40);
    zx_test_finish();
    return 0;
}
