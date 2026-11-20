#ifndef TSCONF_VIDEO_INTERNAL_H
#define TSCONF_VIDEO_INTERNAL_H

#include <tsconf/video.h>

typedef struct {
    uint16_t mode;
    zx_ram_page_t page;
    zx_window_t base;
} ts__draw_surface_t;

zx_status_t ts__video_check_mode(uint16_t mode) __z88dk_fastcall;
zx_status_t ts__video_select_draw_surface(const ts__draw_surface_t *surface) __z88dk_fastcall;

#endif
