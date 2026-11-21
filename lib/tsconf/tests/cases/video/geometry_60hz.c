#include <tsconf.h>
#include <zx_test.h>

int main(void) {
    zx_video_size_t raster = {1, 2};
    zx_video_size_t canvas = {3, 4};
    zx_console_size_t grid = {5, 6};
    uint32_t period = 0;

    zx_test_init();
    ZX_ASSERT(zx_frame_period(&period) == ZX_OK && period == 58688ul);
    ZX_ASSERT(ts_irq_set_frame_position(223, 261, 0) == ZX_OK);
    ZX_ASSERT(ts_irq_set_frame_position(0, 262, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_irq_set_frame_position(0, 10, 1) == ZX_UNSUPPORTED);
    ZX_ASSERT(ts_video_get_raster_size(&raster) != ZX_OK && raster.width == 1 &&
              raster.height == 2);
    ZX_ASSERT(zx_graphics_get_size(&canvas) == ZX_NOT_INITIALIZED && canvas.width == 3 &&
              canvas.height == 4);
    ZX_ASSERT(zx_console_get_size(&grid) != ZX_OK && grid.columns == 5 && grid.rows == 6);

    zx_set_video_mode(TS_VIDEO_TEXT_720X288 | TS_VIDEO_FLAG_HIDE_GFX);
    ZX_ASSERT(zx_set_draw_buffer(TS_VIDEO_16C_360X288, 0x50, NULL) == ZX_OK);
    ZX_ASSERT(ts_video_get_raster_size(&raster) == ZX_OK && raster.width == 720 &&
              raster.height == 240);
    ZX_ASSERT(zx_graphics_get_size(&canvas) == ZX_OK && canvas.width == 512 &&
              canvas.height == 512);
    ZX_ASSERT(zx_console_get_size(&grid) == ZX_OK && grid.columns == 45 && grid.rows == 30);
    ZX_ASSERT(zx_console_gotoxy(44, 29) == ZX_OK && zx_console_gotoxy(44, 30) != ZX_OK);

    zx_set_video_mode(TS_VIDEO_256C_320X200 | TS_VIDEO_FLAG_HIDE_GFX);
    ZX_ASSERT(zx_set_draw_buffer(TS_VIDEO_TEXT_720X288, 0x60, ZX_WINDOW_3) == ZX_OK);
    ZX_ASSERT(ts_video_get_raster_size(&raster) == ZX_OK && raster.width == 320 &&
              raster.height == 200);
    ZX_ASSERT(zx_graphics_get_size(&canvas) == ZX_UNSUPPORTED && canvas.width == 512 &&
              canvas.height == 512);
    ZX_ASSERT(zx_console_get_size(&grid) == ZX_OK && grid.columns == 90 && grid.rows == 30);
    ZX_ASSERT(zx_console_gotoxy(89, 29) == ZX_OK && zx_console_gotoxy(89, 30) != ZX_OK);
    ZX_ASSERT(ts_video_get_raster_size(NULL) != ZX_OK &&
              zx_graphics_get_size(NULL) == ZX_INVALID_ARGUMENT &&
              zx_console_get_size(NULL) != ZX_OK);
    zx_test_finish();
    return 0;
}
