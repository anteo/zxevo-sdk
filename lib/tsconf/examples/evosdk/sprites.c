/* Adapted from Shiru / Alone Coder's public-domain evosdk example_sprites.
 * Preserve the 22 bouncing balls and original images; use the TSConf TSU
 * instead of the original background-save/software-sprite engine. */
#include "demo.h"
#include "resources.h"

#define BALL_COUNT 22
static struct {
    int16_t x, y;
    int8_t dx, dy;
} balls[BALL_COUNT];
static ts_sprite_t sprites[BALL_COUNT];

int main(void) {
    uint8_t i;
    demo_begin();
    upload(&image_resources[0], SCREEN_PAGE);
    upload(&sprite_resource, ATLAS_PAGE);
    set_palette(image_palettes[0], 0, 3);
    set_palette(sprite_palette, 1, 3);
    srand(1);
    for (i = 0; i < BALL_COUNT; ++i) {
        balls[i].x = 1 + rand() % 150;
        balls[i].y = 1 + rand() % 182;
        balls[i].dx = rand() & 1 ? -1 : 1;
        balls[i].dy = rand() & 1 ? -1 : 1;
        sprites[i].tile = 0x1000u | (2u * (i & 3));
    }
    sprites_begin();
    show_screen(SCREEN_PAGE);
    while (!quit()) {
        for (i = 0; i < BALL_COUNT; ++i) {
            sprites[i].x = (1u << 9) | (2u * balls[i].x);
            sprites[i].y = TS_SPRITE_ACTIVE | (1u << 9) | balls[i].y;
            if (balls[i].x == 152 || balls[i].x == 0) balls[i].dx = -balls[i].dx;
            if (balls[i].y == 184 || balls[i].y == 0) balls[i].dy = -balls[i].dy;
            balls[i].x += balls[i].dx;
            balls[i].y += balls[i].dy;
        }
        frame();
        sprites_write(sprites, BALL_COUNT);
    }
    demo_end();
    return 0;
}
