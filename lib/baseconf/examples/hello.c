#include <zx/console.h>
#include <zx/video.h>
#include <zx/interrupt.h>
#include <stdlib.h>

int main(void) {
    const zx_video_surface_t screen = {
        .mode = ZX_VIDEO_ZX_256,
        .page0 = 5,
    };
    /* BASIC 48 starts with screen page 5 in W1. Keep its paging and stack. */
    if (zx_draw_surface(&screen, ZX_WINDOW_1, NULL) != ZX_OK) return 1;

    zx_set_colors(COLOR_BLACK, COLOR_WHITE, COLOR_BLACK);
    if (zx_console_clear() != ZX_OK) return 1;

    if (zx_console_puts("Hello, ZX Evolution!\n") != ZX_OK) return 1;

    msleep(3000);

    return 0;
}
