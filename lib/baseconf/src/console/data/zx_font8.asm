        MODULE zx_font8
INCLUDE "font/z80/zx_font.inc"
INCLUDE "console/font_flags.inc"

SECTION rodata_clib
PUBLIC _zx_font8
EXTERN _CRT_FONT
EXTERN _bc__font8_draw

_zx_font8:
        ZX_FONT8_DESCRIPTOR _CRT_FONT,_bc__font8_draw,BC_FONT_TEXT_BACKEND
