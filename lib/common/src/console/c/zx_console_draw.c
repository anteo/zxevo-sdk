#include "../internal.h"

zx_status_t zx_console_draw(uint8_t column, uint8_t row, const char *text) {
    return zx_console_draw_op(column, row, text, zx__console_text_bg);
}

zx_status_t zx_console_draw_op(uint8_t column, uint8_t row, const char *text,
                               zx_text_bg_t background) {
    zx_console_size_t size;
    zx_status_t status;
    uint8_t length = 0;
    uint8_t room;

    if (!text || (background != ZX_TEXT_OPAQUE && background != ZX_TEXT_TRANSPARENT))
        return ZX_INVALID_ARGUMENT;
    status = zx_console_get_size(&size);
    if (status != ZX_OK) return status;
    if (column >= size.columns || row >= size.rows) return ZX_INVALID_ARGUMENT;

    room = size.columns - column;
    while (length < room && (uint8_t)text[length] >= 32u) ++length;
    return length ? zx__console_draw_run(column, row, text, length, background) : ZX_OK;
}
