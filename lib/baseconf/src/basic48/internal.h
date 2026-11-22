#ifndef BC_BASIC48_INTERNAL_H
#define BC_BASIC48_INTERNAL_H

#include <baseconf/basic48.h>
#include "../memory/internal.h"
#include "../video/internal.h"

enum { BC_BASIC48_IDLE, BC_BASIC48_DRAWING, BC_BASIC48_WINDOWS_RELEASED };

typedef struct {
    uint8_t phase, irq, border, paging, split;
    bc_video_mode_t mode;
    zx_ram_page_t page;
    bc_window_config_t w1, w3;
} bc__basic48_video_t;

extern bc__basic48_video_t bc__basic48_video;
void bc__basic48_release_windows(void);

#endif
