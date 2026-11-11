        MODULE zx_font5
INCLUDE "font/z80/zx_font.inc"
INCLUDE "console/font_flags.inc"

SECTION rodata_clib
PUBLIC _zx_font5
EXTERN _zx_font5_data
EXTERN _bc__font5_draw

_zx_font5:
        ZX_FONT5_DESCRIPTOR _zx_font5_data,_bc__font5_draw,BC_FONT_TEXT_BACKEND
