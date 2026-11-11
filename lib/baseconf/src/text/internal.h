#ifndef BASECONF_TEXT_INTERNAL_H
#define BASECONF_TEXT_INTERNAL_H

#include <baseconf.h>
#include <baseconf/font.h>
#include <baseconf/video.h>

/* Hardware-text backend shared with the console adapters. */
uint8_t bc__text_encode_attribute(void);
void bc__text_cell_write(bc_video_mode_t mode, bc_surface_t surface, uint8_t x, uint8_t y,
                         uint8_t character);
uint8_t bc__text_cell_read(bc_video_mode_t mode, bc_surface_t surface, uint8_t x, uint8_t y);

/* Draw up to limit bytes, stopping at NUL or the right edge. */
zx_status_t bc__text_draw_font(uint8_t column, uint8_t row, const char *text, const zx_font_t *font,
                               uint16_t limit, zx_text_bg_t background);

#endif
