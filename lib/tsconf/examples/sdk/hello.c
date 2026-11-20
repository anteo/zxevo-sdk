#include <tsconf/memory.h>
#include <zx/console.h>
#include <zx/video.h>
#include <zx/interrupt.h>
#include <stdlib.h>

int main(void) {
    const zx_video_surface_t screen = {
        .mode = ZX_VIDEO_ZX_256,
        .page0 = 5,
    };
    zx_ram_page_t saved_w3 = ts_memory_get_page3();
    zx_status_t status;

    /* Keep the BASIC stack and system variables in W1 while drawing via W3. */
    if (zx_display_surface(&screen) != ZX_OK) return 1;
    if (zx_draw_surface(&screen, ZX_WINDOW_3, NULL) != ZX_OK) return 1;

    zx_set_colors(COLOR_BLACK, COLOR_WHITE, COLOR_BLACK);
    status = zx_console_clear();
    if (status == ZX_OK) status = zx_console_puts("Hello, ZX Evolution!\n");
    if (ts_map_ram_page(ZX_WINDOW_3, saved_w3) != ZX_OK || status != ZX_OK) return 1;

    msleep(3000);
    return 0;
}
