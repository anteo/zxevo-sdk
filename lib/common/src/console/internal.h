#ifndef ZX_CONSOLE_INTERNAL_H
#define ZX_CONSOLE_INTERNAL_H

#include <zx/console.h>

extern zx_text_bg_t zx__console_text_bg;

/* Draw a validated nonempty run inside one row without moving the cursor. */
zx_status_t zx__console_draw_run(uint8_t column, uint8_t row, const char *text, uint8_t length,
                                 zx_text_bg_t background);

#endif
