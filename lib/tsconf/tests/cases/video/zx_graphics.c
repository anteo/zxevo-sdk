#include <string.h>
#include <tsconf.h>
#include <zx_test.h>

static volatile uint8_t *const screen = (volatile uint8_t *)0xc000;

static uint8_t pixel(uint8_t x, uint8_t y) {
    uint16_t offset = ((uint16_t)(y & 7) << 8) | ((uint16_t)(y & 0xc0) << 5) |
                      ((uint16_t)(y & 0x38) << 2) | (x >> 3);
    return screen[offset] & (0x80u >> (x & 7));
}

int main(void) {
    uint8_t i, index;
    const ts_surface_t surface = {TS_VIDEO_ZX, 0x60, screen};

    zx_test_init();
    ts_memory_set_page3(0x60);
    memset((void *)screen, 0, 0x1800);
    screen[0x1800] = 0xa5;
    screen[0x1aff] = 0x5a;

    ZX_ASSERT(ts_video_select_draw_surface(&surface) == ZX_OK);
    zx_draw_plot(255, 191);
    zx_draw_plot(0, 192);
    zx_draw_plot(-1, 0);
    zx_draw_plot(256, 0);
    ZX_ASSERT(screen[0x17ff] == 1 && screen[0] == 0);
    ZX_ASSERT(screen[0x1800] == 0xa5 && screen[0x1aff] == 0x5a);
    zx_test_step_marker("bitmap-point");

    zx_draw_line(-32768, -32768, 7, 7);
    for (i = 0; i < 8; ++i) {
        ZX_ASSERT(screen[256u * i] == (0x80u >> i));
    }
    zx_draw_line(10, 20, 8, 16);
    ZX_ASSERT(pixel(10, 20) && pixel(10, 19) && pixel(9, 18) && pixel(9, 17) && pixel(8, 16) &&
              !pixel(9, 19));
    zx_draw_line(9, 9, 9, 9);
    ZX_ASSERT(pixel(9, 9));
    zx_draw_line(30, -10, 33, -1);
    ZX_ASSERT(!pixel(33, 0));
    ZX_ASSERT(screen[0x1800] == 0xa5 && screen[0x1aff] == 0x5a);
    zx_test_step_marker("clipped-lines");

    zx_draw_fill_rect(3, 8, 14, 1);
    ZX_ASSERT(screen[0x20] == 0x1f && screen[0x21] == 0xff && screen[0x22] == 0x80);
    zx_draw_clear_rect(5, 8, 7, 1);
    ZX_ASSERT(screen[0x20] == 0x18 && screen[0x21] == 0x0f && screen[0x22] == 0x80);
    zx_draw_fill_rect(-2, -1, 5, 2);
    ZX_ASSERT(screen[0] == 0xe0 && screen[0x1800] == 0xa5);

    screen[0x1800] = 0xe5;          /* FLASH + BRIGHT, ink 5 and paper 4 */
    ZX_ASSERT(zx_read_pixel_index(0, 0, &index) == ZX_OK && index == 13);
    ZX_ASSERT(zx_read_pixel_index(3, 0, &index) == ZX_OK && index == 12);
    ZX_ASSERT(zx_read_pixel_index(256, 0, &index) != ZX_OK && index == 12);
    ZX_ASSERT(zx_read_pixel_index(0, 192, &index) != ZX_OK && index == 12);
    ZX_ASSERT(zx_read_pixel_index(0, 0, NULL) != ZX_OK);

    zx_test_finish();
    return 0;
}
