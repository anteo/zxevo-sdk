#include <baseconf.h>
#include <conio.h>
#include <stdio.h>
#include <intrinsic.h>

int main(void) {
    static char long_text[301];
    uint16_t i;
    int printed;
    intrinsic_di();
    bc_ers_set_profile(BC_ERS_NONE);
    bc_set_pinned_windows(0x07);
    if (bc_set_video_mode(BC_VIDEO_ZX_256) != ZX_OK) return 2;
    if (zx_show_screen(ZX_SCREEN_0) != ZX_OK) return 3;
    if (zx_select_draw_screen(ZX_SCREEN_0) != ZX_OK) return 4;
    if (zx_console_set_font(&zx_font5) != ZX_OK) return 5;
    clrscr();
    printf("CRT printf 5x7: %s %d %02X\n", "pq", -42, 42u);
    puts("01234567890123456789012345678901234567890123456789");
    gotoxy(0, 5);
    printf("gotoxy and wrap");
    for (i = 0; i < 300u; ++i) long_text[i] = (char)('a' + i % 26u);
    long_text[300] = 0;
    gotoxy(0, 10);
    printed = printf("%s", long_text);
    printf("\nlength=%d", printed);
    return 0;
}
