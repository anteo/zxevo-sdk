#include <string.h>
#include <tsconf.h>
#include <zx_test.h>

static volatile uint8_t *const w3 = (volatile uint8_t *)0xc000;

int main(void) {
    const ts_surface_t canvas16 = {TS_VIDEO_16C, 0x50, NULL};
    const ts_surface_t canvas256 = {TS_VIDEO_256C, 0x40, NULL};
    const ts_surface_t misaligned256 = {TS_VIDEO_256C, 0x48, NULL};
    const ts_surface_t text = {TS_VIDEO_TEXT, 0x41, w3};
    uint8_t index = 0x69;

    zx_test_init();
    ZX_ASSERT(zx_console_printf("no surface") == -1);
    ZX_ASSERT(zx_read_pixel_index(0, 0, &index) != ZX_OK && index == 0x69);
    ts_memory_set_page3(0x50);
    memset((void *)w3, 0, 0x4000);
    w3[0x3f00] = 0xa5;
    ts_memory_set_page3(0x51);
    memset((void *)w3, 0, 0x4000);
    ts_memory_set_page3(0x7e);
    w3[0] = 0x69;
    ZX_ASSERT(ts_video_select_draw_surface(&canvas16) == ZX_OK);
    zx_set_ink(0xfb);
    zx_draw_plot(1, 63);
    zx_set_ink(3);
    zx_draw_vline(0, 62, 65);
    ZX_ASSERT(zx_read_pixel_index(0, 63, &index) == ZX_OK && index == 3);
    ZX_ASSERT(zx_read_pixel_index(1, 63, &index) == ZX_OK && index == 0x0b);
    ZX_ASSERT(zx_read_pixel_index(0, 64, &index) == ZX_OK && index == 3);
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && w3[0] == 0x69);
    ts_memory_set_page3(0x50);
    ZX_ASSERT(w3[0x3e00] == 0x30 && w3[0x3f00] == 0x3b && w3[0x3f01] == 0);
    ts_memory_set_page3(0x51);
    ZX_ASSERT(w3[0] == 0x30 && w3[0x100] == 0x30 && w3[0x200] == 0);
    zx_test_step_marker("16c-nibbles-and-page-crossing");

    ts_memory_set_page3(0x7e);
    zx_set_ink(0xf7);
    zx_draw_fill_rect(1, 63, 4, 2);
    zx_set_paper(8);
    zx_draw_clear_rect(3, 64, 1, 1);
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && w3[0] == 0x69);
    ts_memory_set_page3(0x50);
    ZX_ASSERT(w3[0x3f00] == 0x37 && w3[0x3f01] == 0x77 && w3[0x3f02] == 0x70);
    ts_memory_set_page3(0x51);
    ZX_ASSERT(w3[0] == 0x37 && w3[1] == 0x78 && w3[2] == 0x70 && w3[3] == 0);

    ts_memory_set_page3(0x40);
    w3[0x3fff] = 0;
    ts_memory_set_page3(0x41);
    memset((void *)w3, 0, 0x4000);
    ts_memory_set_page3(0x7e);
    ZX_ASSERT(ts_video_select_draw_surface(&canvas256) == ZX_OK);
    ZX_ASSERT(ts_video_select_draw_surface(&misaligned256) != ZX_OK);
    zx_set_ink(0xa5);
    zx_draw_plot(511, 31);
    zx_set_ink(0xb7);
    zx_draw_hline(510, 513, 32);
    zx_set_ink(0xff);
    zx_draw_plot(-1, 32);
    ZX_ASSERT(zx_read_pixel_index(511, 31, &index) == ZX_OK && index == 0xa5);
    ZX_ASSERT(zx_read_pixel_index(511, 32, &index) == ZX_OK && index == 0xb7);
    ZX_ASSERT(zx_read_pixel_index(512, 32, &index) != ZX_OK && index == 0xb7);
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && w3[0] == 0x69);
    ts_memory_set_page3(0x40);
    ZX_ASSERT(w3[0x3fff] == 0xa5);
    ts_memory_set_page3(0x41);
    ZX_ASSERT(ts_video_select_draw_surface(&text) == ZX_OK);
    ZX_ASSERT(zx_read_pixel_index(0, 0, &index) != ZX_OK && index == 0xb7);
    zx_draw_plot(0, 0);
    ZX_ASSERT(w3[0] == 0 && w3[0x1fd] == 0 && w3[0x1fe] == 0xb7 && w3[0x1ff] == 0xb7 &&
              w3[0x200] == 0);
    zx_test_step_marker("256c-indices-and-clipping");

    ts_console_set_attribute(0x1e);
    ZX_ASSERT(zx_console_gotoxy(63, 0) == ZX_OK);
    ZX_ASSERT(zx_console_printf("%02X", 42u) == 2);
    ZX_ASSERT(w3[63] == '2' && w3[0x100] == 'A');
    ZX_ASSERT(w3[0xbf] == 0x1e && w3[0x180] == 0x1e);
    zx_test_step_marker("printf-without-stdio");

    ts_memory_set_page3(0x7e);
    ZX_ASSERT(ts_video_select_draw_surface(&canvas256) == ZX_OK);
    zx_set_ink(0xcc);
    zx_draw_fill_rect(509, 31, 32767, 2);
    zx_set_ink(0xdd);
    zx_draw_fill_rect(509, 31, 3, 0);
    ZX_ASSERT(ts_memory_get_page3() == 0x7e && w3[0] == 0x69);
    ts_memory_set_page3(0x40);
    ZX_ASSERT(w3[0x3ffd] == 0xcc && w3[0x3ffe] == 0xcc && w3[0x3fff] == 0xcc);
    ts_memory_set_page3(0x41);
    ZX_ASSERT(w3[0x1fc] == 0 && w3[0x1fd] == 0xcc && w3[0x1fe] == 0xcc && w3[0x1ff] == 0xcc &&
              w3[0x200] == 0);
    zx_test_finish();
    return 0;
}
