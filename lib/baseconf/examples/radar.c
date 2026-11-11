#include <zx/console.h>
#include <zx/graphics.h>
#include <zx/interrupt.h>

enum { CENTER_X = 128, CENTER_Y = 92, RADIUS = 58 };

static const volatile uint8_t *const basic_frames = (const volatile uint8_t *)0x5c78u;

static const int8_t bearings[][2] = {{0, -58},  {29, -50}, {50, -29},  {58, 0},
                                     {50, 29},  {29, 50},  {0, 58},    {-29, 50},
                                     {-50, 29}, {-58, 0},  {-50, -29}, {-29, -50}};

static void sweep(uint8_t bearing) {
    zx_draw_line_xor(CENTER_X, CENTER_Y, CENTER_X + bearings[bearing][0],
                     CENTER_Y + bearings[bearing][1]);
}

int main(void) {
    uint8_t turn, bearing;
    zx_status_t status;

    status = zx_select_draw_screen(ZX_SCREEN_0);
    if (status != ZX_OK) return status;
    zx_set_colors(COLOR_BLACK, COLOR_GREEN | COLOR_BRIGHT, COLOR_BLACK);
    status = zx_console_clear();
    if (status != ZX_OK) return status;
    status = zx_console_set_font(&zx_font5);
    if (status != ZX_OK) return status;
    status = zx_console_draw(2, 1, "NORTH COAST / RADAR WATCH");
    if (status != ZX_OK) return status;
    status = zx_console_draw(2, 21, "TWO CONTACTS   RANGE 60 NM");
    if (status != ZX_OK) return status;

    status = zx_graphics_begin();
    if (status != ZX_OK) return status;
    zx_draw_circle(CENTER_X, CENTER_Y, RADIUS);
    zx_draw_circle(CENTER_X, CENTER_Y, 38);
    zx_draw_circle(CENTER_X, CENTER_Y, 18);
    zx_draw_hline(CENTER_X - RADIUS, CENTER_X + RADIUS, CENTER_Y);
    zx_draw_vline(CENTER_X, CENTER_Y - RADIUS, CENTER_Y + RADIUS);
    zx_draw_fill_rect(151, 60, 3, 3);
    zx_draw_fill_rect(97, 112, 3, 3);
    status = zx_graphics_end();
    if (status != ZX_OK) return status;

    for (turn = 0; turn < 4; ++turn) {
        for (bearing = 0; bearing < sizeof(bearings) / sizeof(*bearings); ++bearing) {
            /* Drawing the same XOR ray twice restores the grid and contacts. */
            sweep(bearing);
            status = zx_wait_frames(basic_frames, 5);
            sweep(bearing);
            if (status != ZX_OK) return status;
        }
    }
    return ZX_OK;
}
