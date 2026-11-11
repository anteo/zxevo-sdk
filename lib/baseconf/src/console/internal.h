#ifndef BASECONF_CONSOLE_INTERNAL_H
#define BASECONF_CONSOLE_INTERNAL_H

#include <baseconf.h>
#include <baseconf/video.h>
#include <baseconf/font.h>

uint8_t bc__console_is_text_mode(bc_video_mode_t mode);
void bc__console_graphics_cell_write(uint8_t column, uint8_t row, uint8_t character);
void bc__console_cell_write(bc_video_mode_t mode, bc_surface_t surface, uint8_t x, uint8_t y,
                            uint8_t character);
void bc__console_scroll(void);

extern const zx_font_t *bc_console_active_font;
extern uint8_t bc_console_font_advance;
/* Classic z88dk console geometry and cursor, shared with stdio. */
extern uint8_t _console_x, _console_y, _console_w, _console_h;
void bc__console_set_geometry(uint8_t columns, uint8_t rows);
void bc__console_geometry(void);
void bc__console_newline(void);
zx_status_t bc__console_control(uint8_t c) __z88dk_fastcall;
void bc__font8_draw(uint16_t x, uint16_t y, const zx_font_t *font, uint8_t code, uint8_t ink,
                    uint8_t paper);

#endif
