#ifndef XNX_GAME_H
#define XNX_GAME_H
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <input.h>
#include <games.h>
#include <tsconf.h>

typedef uint8_t u8;
typedef int8_t i8;
typedef uint16_t u16;
typedef int16_t i16;
typedef uint32_t u32;
#define TRUE 1
#define FALSE 0
#define JOY_RIGHT MOVE_RIGHT
#define JOY_LEFT MOVE_LEFT
#define JOY_DOWN MOVE_DOWN
#define JOY_UP MOVE_UP
#define JOY_FIRE MOVE_FIRE
#define BRIGHT_MIN 0
#define BRIGHT_MID 3
#define BRIGHT_MAX 6
#define SPRITE_END 0xff00u

extern volatile uint8_t xnx_ticks;

void xnx_init(void);
void xnx_select_image(uint8_t image);
void xnx_draw_tile(uint8_t x, uint8_t y, uint16_t tile);
void xnx_draw_tile_key(uint8_t x, uint8_t y, uint16_t tile);
void xnx_draw_image(uint8_t x, uint8_t y, uint8_t image);
void xnx_brightness(uint8_t brightness);
void xnx_palette(uint8_t palette);
void xnx_clear(uint8_t color);
void xnx_present(void);
void xnx_sprites_start(void);
void xnx_sprites_stop(void);
void xnx_sprite(uint8_t index, uint8_t x, uint8_t y, uint16_t image);
void xnx_music(uint8_t music);
void xnx_music_stop(void);
void xnx_effect(uint8_t effect, int8_t volume);
void xnx_sample(uint8_t sample);
void xnx_frame(void);
void xnx_delay(uint16_t frames);
uint8_t xnx_controls(void);
void xnx_poll_input(void);
uint8_t xnx_pause_pressed(void);
void xnx_audio_tick(void);
#endif
