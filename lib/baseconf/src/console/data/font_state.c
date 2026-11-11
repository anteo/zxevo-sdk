#include <zx/font.h>

#ifdef BASECONF_CONSOLE_NO_DEFAULT_FONT
const zx_font_t *bc_console_active_font;
#else
const zx_font_t *bc_console_active_font = &zx_font8;
#endif
