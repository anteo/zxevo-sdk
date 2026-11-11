#include <tsconf/memory.h>
#include <tsconf/video.h>
#include <zx/video.h>

zx_status_t zx_select_draw_screen(zx_screen_t screen) {
    ts_surface_t surface = {TS_VIDEO_ZX | TS_VIDEO_256X192, 5, (volatile void *)0x4000u};

    if (screen == ZX_SCREEN_1) {
        surface.page = 7;
        if (ts_memory_get_page2() == 7)
            surface.base = (volatile void *)0x8000u;
        else if (ts_memory_get_page3() == 7)
            surface.base = (volatile void *)0xc000u;
        else
            return ZX_UNAVAILABLE;
    } else if (screen != ZX_SCREEN_0) {
        return ZX_INVALID_ARGUMENT;
    }
    return ts_video_select_draw_surface(&surface);
}
