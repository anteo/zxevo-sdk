#include <baseconf/memory.h>
#include <baseconf/video.h>
#include <zx/console.h>
#include <zx/graphics.h>
#include <zx/interrupt.h>

#define PAINT_STACK_SIZE 512

enum { SKY = COLOR_BLUE, RIDGE = COLOR_MAGENTA, LAMP = COLOR_YELLOW | COLOR_BRIGHT };

static const volatile uint8_t *const basic_frames = (const volatile uint8_t *)0x5c78u;
static const volatile uint8_t *const basic_border = (const volatile uint8_t *)0x5c48u;

uint8_t night_train_stack[PAINT_STACK_SIZE];

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

/* BASIC 48 can leave 7FFD locked. Unlock only around the screen select. */
static zx_status_t select_screen(zx_screen_t screen) {
    uint8_t paging = bc_readback_register(0x0a);
    zx_status_t status, restore;

    if (BC_PAGING_SCREEN(paging) == screen) return ZX_OK;
    if (!BC_PAGING_IS_LOCKED_128K(paging) || !(bc_readback_register(0x0b) & 4u))
        return bc_select_screen(screen);

    status = bc_set_addressing(BC_ADDRESSING_1024K);
    if (status != ZX_OK) return status;
    status = bc_select_screen(screen);
    restore = bc_set_addressing(BC_ADDRESSING_128K);
    return restore != ZX_OK ? restore : status;
}

/* Paint the alternate hardware screen (pages 3 and 7) with W1 and W3 free.
 * Code and the temporary stack are in W2. INT stays masked until W1 again
 * maps BASIC's system variables and caller stack. */
zx_status_t night_train_paint(void) {
    bc_window_config_t saved_w1, saved_w2, saved_w3;
    bc_surface_t surface = bc_screen_surface(BC_VIDEO_ATM_320, ZX_SCREEN_1);
    bc_map_t map = bc_get_active_map();
    uint8_t pins = bc_get_pinned_windows();
    zx_status_t status, w1_status, w3_status;

    status = bc_get_window_config(map, ZX_WINDOW_1, &saved_w1);
    if (status != ZX_OK) return status;
    status = bc_get_window_config(map, ZX_WINDOW_2, &saved_w2);
    if (status != ZX_OK) return status;
    status = bc_get_window_config(map, ZX_WINDOW_3, &saved_w3);
    if (status != ZX_OK) return status;
    if (saved_w1.kind != BC_RAM || saved_w1.physical_page != 5 ||
        saved_w2.physical_page == surface.page0 || saved_w2.physical_page == surface.page1 ||
        saved_w3.physical_page == surface.page0 || saved_w3.physical_page == surface.page1)
        return ZX_UNSAFE_CONTEXT;

    bc_set_pinned_windows((1u << ZX_WINDOW_0) | (1u << ZX_WINDOW_2));
    status = bc_map_ram_page(ZX_WINDOW_1, surface.page0);
    if (status == ZX_OK) status = bc_map_ram_page(ZX_WINDOW_3, surface.page1);
    if (status == ZX_OK) status = bc_select_draw_surface(&surface);
    if (status == ZX_OK) status = draw_station();
    if (status == ZX_OK) status = select_screen(ZX_SCREEN_1);
    if (status == ZX_OK) status = bc_set_video_mode(BC_VIDEO_ATM_320);

    w1_status = bc_configure_window(map, ZX_WINDOW_1, &saved_w1);
    w3_status = bc_configure_window(map, ZX_WINDOW_3, &saved_w3);
    bc_set_pinned_windows(pins);
    if (w1_status != ZX_OK) return w1_status;
    return w3_status != ZX_OK ? w3_status : status;
}

/* Call the painter on its private stack and restore BASIC's stack on return.
 * The painter restores W1 before returning. SDCC status is returned in L. */
/* clang-format off */
static zx_status_t paint_on_private_stack(void) __naked {
    __asm
        ld hl,0
        add hl,sp
        ld sp,_night_train_stack + PAINT_STACK_SIZE
        push hl
        call _night_train_paint
        ld a,l
        pop hl
        ld sp,hl
        ld l,a
        ret
    __endasm;
}
/* clang-format on */

int main(void) {
    uint8_t irq, border;
    zx_status_t status, restore;

    if (bc_get_video_mode() != BC_VIDEO_ZX_256 ||
        BC_PAGING_SCREEN(bc_readback_register(0x0a)) != ZX_SCREEN_0)
        return ZX_UNSAFE_CONTEXT;

    border = (*basic_border >> 3) & 7;
    irq = zx_interrupt_save_disable();
    status = paint_on_private_stack();
    zx_interrupt_restore(irq);
    if (status == ZX_OK) status = zx_wait_frames(basic_frames, 250);

    irq = zx_interrupt_save_disable();
    restore = select_screen(ZX_SCREEN_0);
    if (restore == ZX_OK) restore = bc_set_video_mode(BC_VIDEO_ZX_256);
    zx_set_border_color(border);
    zx_interrupt_restore(irq);
    return restore != ZX_OK ? restore : status;
}
