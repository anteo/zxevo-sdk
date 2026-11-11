#ifndef BASECONF_GRAPHICS_INTERNAL_H
#define BASECONF_GRAPHICS_INTERNAL_H

#include <stdint.h>

extern int bc_graphics_x, bc_graphics_y;
extern uint8_t bc_graphics_pen_down;
extern uint16_t bc_graphics_width, bc_graphics_height;

/* Native pixel writer selected for the active surface and operation. */
typedef void (*bc_draw_callback_t)(void);
extern bc_draw_callback_t bc_draw_callback;

#endif
