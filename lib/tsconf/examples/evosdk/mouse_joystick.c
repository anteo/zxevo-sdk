/* Adapted from the public-domain evosdk example_mouse_joystick.
 * z88dk supplies mouse/joystick input; TSConf supplies the hardware cursor. */
#include "demo.h"
#include <arch/zx/zx_input.h>
#include "resources.h"

/* Required state for the existing z88dk Kempston driver. */
uint8_t in_KempcoordX, in_KempcoordY, in_KemprawX, in_KemprawY;

int main(void) {
    uint16_t mx, my;
    int16_t x = 80, y = 100;
    uint8_t buttons, joy, border;
    ts_sprite_t cursor;
    demo_begin();
    upload(&image_resources[0], SCREEN_PAGE);
    upload(&sprite_resource, ATLAS_PAGE);
    set_palette(image_palettes[0], 0, 3);
    set_palette(sprite_palette, 1, 3);
    in_MouseKempInit();
    in_MouseKempSetPos(128, 96);
    sprites_begin();
    cursor.tile = 0x1000;
    show_screen(SCREEN_PAGE);
    while (!quit()) {
        frame();
        in_MouseKemp(&buttons, &mx, &my);
        /* Recenter the 256x192 z88dk driver each tick so the application can
         * use evosdk's half-pixel X coordinates and full 320x200 raster.
         * Its built-in rejection of large mouse jumps remains in effect. */
        x += ((int16_t)mx - 128) / 2;
        y += (int16_t)my - 96;
        in_MouseKempSetPos(128, 96);
        joy = controls();
        if (joy & MOVE_LEFT) --x;
        if (joy & MOVE_RIGHT) ++x;
        if (joy & MOVE_UP) y -= 2;
        if (joy & MOVE_DOWN) y += 2;
        if (x < 0) x = 0;
        if (x > 152) x = 152;
        if (y < 0) y = 0;
        if (y > 184) y = 184;
        /* Classic in_MouseKemp exposes two buttons. Read the middle button
         * through z88dk inp(), without adding another SDK input function. */
        if (!(inp(0xfadfu) & 4u)) buttons |= in_MMID;
        border = buttons == in_MLEFT ? 12 : buttons == in_MRIGHT ? 15 : buttons == in_MMID ? 14 : 0;
        ts_video_set_border(border);
        cursor.x = (1u << 9) | (2u * x);
        cursor.y = TS_SPRITE_ACTIVE | (1u << 9) | y;
        sprites_write(&cursor, 1);
    }
    demo_end();
    return 0;
}
