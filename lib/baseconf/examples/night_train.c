#include <baseconf/basic48.h>
#include <zx/basic48.h>
#include <zx/console.h>
#include <zx/graphics.h>

enum { SKY = COLOR_BLUE, RIDGE = COLOR_MAGENTA, LAMP = COLOR_YELLOW | COLOR_BRIGHT };

static void draw_carriage(int16_t x) {
    uint8_t window;

    zx_set_ink(COLOR_RED);
    zx_draw_fill_rect(x, 116, 84, 32);
    zx_set_ink(COLOR_RED | COLOR_BRIGHT);
    zx_draw_hline(x + 3, x + 80, 115);
    zx_draw_hline(x, x + 83, 117);
    zx_set_ink(LAMP);
    for (window = 0; window < 4; ++window) {
        int16_t left = x + 7 + 18 * window;
        zx_draw_fill_rect(left, 123, 13, 10);
        zx_set_ink(COLOR_RED);
        zx_draw_vline(left + 6, 123, 132);
        zx_set_ink(LAMP);
    }
    zx_set_ink(COLOR_BLACK);
    zx_draw_circle(x + 16, 149, 5);
    zx_draw_circle(x + 67, 149, 5);
}

static zx_status_t draw_station(void) {
    int16_t x;
    zx_status_t status;

    zx_set_colors(COLOR_BLACK, COLOR_WHITE | COLOR_BRIGHT, SKY);
    status = zx_console_clear();
    if (status != ZX_OK) return status;
    status = zx_console_set_font(&zx_font5);
    if (status != ZX_OK) return status;
    status = zx_console_draw_op(2, 1, "NIGHT LOCAL / PLATFORM 1", ZX_TEXT_TRANSPARENT);
    if (status != ZX_OK) return status;
    status = zx_graphics_begin();
    if (status != ZX_OK) return status;

    zx_set_ink(COLOR_WHITE | COLOR_BRIGHT);
    zx_draw_circle(267, 49, 15);
    for (x = 11; x < 320; x += 19) zx_draw_plot(x, 28 + (x & 31));
    zx_set_ink(RIDGE);
    zx_draw_line(0, 113, 68, 63);
    zx_draw_line(68, 63, 139, 111);
    zx_draw_line(139, 111, 202, 77);
    zx_draw_line(202, 77, 319, 113);

    zx_set_ink(COLOR_GREEN);
    zx_draw_fill_rect(0, 155, 320, 45);
    zx_set_ink(COLOR_GREEN | COLOR_BRIGHT);
    zx_draw_hline(0, 319, 169);
    zx_set_ink(COLOR_WHITE);
    zx_draw_hline(0, 319, 155);
    zx_draw_hline(0, 319, 159);
    for (x = 7; x < 320; x += 16) zx_draw_hline(x, x + 7, 161);

    draw_carriage(25);
    draw_carriage(115);
    draw_carriage(205);
    status = zx_graphics_end();
    if (status != ZX_OK) return status;
    zx_set_ink(COLOR_WHITE | COLOR_BRIGHT);
    return zx_console_draw_op(2, 22, "23:48  LAST TRAIN TO THE COAST", ZX_TEXT_TRANSPARENT);
}

int main(void) {
    zx_status_t status = bc_basic48_video_begin(BC_VIDEO_ATM_320);
    zx_status_t restore;
    if (status != ZX_OK) return status;

    status = draw_station();
    if (status == ZX_OK) status = bc_basic48_video_present();
    if (status == ZX_OK) status = zx_basic48_wait_frames(250);

    restore = bc_basic48_video_end();
    return restore != ZX_OK ? restore : status;
}
