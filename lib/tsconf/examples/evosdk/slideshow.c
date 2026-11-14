/* Adapted from the public-domain evosdk example_slideshow: all five source
 * pictures, black/white fades and the original joystick controls. */
#include "demo.h"
#include "resources.h"

static uint8_t current = 1;
static uint8_t visible_page = SCREEN_PAGE;

static void fade(uint8_t image, uint8_t white, uint8_t incoming) {
    uint8_t i, j;
    for (i = 0; i < 4; ++i) {
        uint8_t level = incoming ? (white ? 6 - i : i) : (white ? 3 + i : 3 - i);
        frame();
        set_palette(image_palettes[image], 0, level);
        for (j = 0; j < 4; ++j) frame();
    }
}

static void show_picture(uint8_t image, uint8_t white, uint8_t fading) {
    uint8_t next = visible_page == SCREEN_PAGE ? OTHER_SCREEN_PAGE : SCREEN_PAGE;
    upload(&image_resources[image], next);
    if (fading) fade(current, white, 0);
    frame();
    visible_page = next;
    set_palette(image_palettes[image], 0, fading ? (white ? 6 : 0) : 3);
    show_screen(visible_page);
    if (fading) fade(image, white, 1);
    current = image;
}

int main(void) {
    uint8_t previous = 0, joy, pressed, next;
    demo_begin();
    show_picture(current, 0, 1);
    while (!quit()) {
        frame();
        joy = controls();
        pressed = joy & (uint8_t)~previous;
        previous = joy;
        if (pressed & (MOVE_LEFT | MOVE_UP)) {
            next = current == 0 ? 4 : current - 1;
            show_picture(next, 0, (pressed & MOVE_LEFT) != 0);
        }
        if (pressed & (MOVE_RIGHT | MOVE_DOWN)) {
            next = current == 4 ? 0 : current + 1;
            show_picture(next, 1, (pressed & MOVE_RIGHT) != 0);
        }
    }
    demo_end();
    return 0;
}
