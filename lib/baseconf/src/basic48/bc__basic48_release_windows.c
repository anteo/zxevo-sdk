#include "internal.h"

/* Called with INT masked, all draw operations ended and the original map
 * active. The configurations came from that map before it was borrowed. */
void bc__basic48_release_windows(void) {
    bc__basic48_video_t *s = &bc__basic48_video;
    if (s->split) {
        bc__mem_apply_window(ZX_WINDOW_1, &s->w1);
        bc__video_invalidate_window(ZX_WINDOW_1);
    }
    bc__mem_apply_window(ZX_WINDOW_3, &s->w3);
    bc__video_invalidate_window(ZX_WINDOW_3);
}
