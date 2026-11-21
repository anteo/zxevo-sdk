#ifndef TSCONF_VIDEO_INTERNAL_H
#define TSCONF_VIDEO_INTERNAL_H

#include <tsconf/video.h>

typedef struct {
    uint8_t config;
    zx_ram_page_t page;
    uint8_t window_high;
} ts__draw_buffer_t;

/* ASM uses this field order and a three-byte stride. Config 0xff is empty. */
extern ts__draw_buffer_t ts_video_prepared_buffers[ZX_DRAW_BUFFER_SLOTS];

zx_status_t ts__video_check_mode(uint16_t mode) __z88dk_fastcall;
zx_status_t ts__video_commit_draw_buffer(const ts__draw_buffer_t *buffer) __z88dk_fastcall;

#endif
