#include <zx/console.h>
#include "../../console/internal.h"
#include "../../text/internal.h"
#include "../../video/internal.h"
#include "../../../../common/src/console/internal.h"
#include "../../../../common/src/printf/internal.h"

/* Consume a printable run in a bitmap row, or one console character. */
int zx__printf_write(const char *text, uint8_t limit, uint8_t stop) {
#ifdef BASECONF_VIDEO_TEXT_GRAPHICS
    const zx_font_t *font = bc_console_active_font;
    if (font && bc_video_draw_surface_state.mode < BC_VIDEO_ATM_TEXT_80) {
        uint8_t code = (uint8_t)*text;
        uint8_t column, row;
        if (code < 32 && code != '\t') {
            bc__console_control(code);
            return 1;
        }
        column = _console_x;
        row = _console_y;
        /* Short fields use the character path to avoid the row setup cost. */
        if (limit >= 4 && column < _console_w && row < _console_h) {
            uint8_t room = _console_w - column;
            uint8_t length = 0;
            if (limit > room) limit = room;
            while (length < limit) {
                code = (uint8_t)text[length];
                if (code < 32 || code > 127 || code == stop) break;
                ++length;
            }
            if (length >= 4) {
                if (bc__text_draw_font(column, row, text, font, length, zx__console_text_bg) !=
                    ZX_OK)
                    return -1;
                if (length == room)
                    bc__console_newline();
                else
                    _console_x = column + length;
                return length;
            }
        }
    }
#else
    (void)limit;
    (void)stop;
#endif
    return zx_console_putc(*text) == ZX_OK ? 1 : -1;
}
