#include <tsconf.h>
#include <zx_test.h>

int main(void) {
    volatile uint8_t *const w3 = (volatile uint8_t *)0xc000u;
    uint8_t row, col;
    zx_test_init();
    ts_map_ram_page(ZX_WINDOW_3, 0x7e);
    w3[0] = 0x6a;
    ZX_ASSERT(ts_video_fill_16c_screen(0x60, 5) == ZX_OK);
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && w3[0] == 0x6a);
    ts_map_ram_page(ZX_WINDOW_3, 0x60);
    ZX_ASSERT(w3[0] == 0x55);
    ts_map_ram_page(ZX_WINDOW_3, 0x63);
    ZX_ASSERT(w3[2047] == 0x55);
    ZX_ASSERT(ts_video_copy_16c_screen(0x60, 0x68) == ZX_OK);
    ts_map_ram_page(ZX_WINDOW_3, 0x68);
    ZX_ASSERT(w3[0] == 0x55);
    ts_map_ram_page(ZX_WINDOW_3, 0x70);
    for (row = 0; row < 8; ++row)
        for (col = 0; col < 4; ++col) w3[(uint16_t)row * 4 + col] = 0x12 + col;
    ZX_ASSERT(ts_video_draw_16c_tile(0x70, 0, 0x60, 2, 3) == ZX_OK);
    ts_map_ram_page(ZX_WINDOW_3, 0x60);
    for (row = 0; row < 8; ++row)
        for (col = 0; col < 4; ++col)
            ZX_ASSERT(w3[6152u + (uint16_t)row * 256 + col] == 0x12 + col);
    ZX_ASSERT(ts_video_copy_16c_tile(0x60, 0x68, 2, 3) == ZX_OK);
    ts_map_ram_page(ZX_WINDOW_3, 0x68);
    for (row = 0; row < 8; ++row)
        for (col = 0; col < 4; ++col)
            ZX_ASSERT(w3[6152u + (uint16_t)row * 256 + col] == 0x12 + col);
    ZX_ASSERT(ts_video_copy_16c_tile(0x60, 0x68, 40, 3) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_video_fill_16c_screen(0x61, 0) == ZX_INVALID_ARGUMENT);
    zx_test_step_marker("packed-dma-copy-fill-tile");
    zx_test_finish();
    return 0;
}
