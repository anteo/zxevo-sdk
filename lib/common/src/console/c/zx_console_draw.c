#include "../internal.h"

zx_status_t zx_console_draw(uint8_t column, uint8_t row, const char *text) {
    return zx_console_draw_op(column, row, text, zx__console_text_bg);
}
