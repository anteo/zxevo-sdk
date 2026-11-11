        MODULE zx_font8
INCLUDE "font/z80/zx_font.inc"
SECTION rodata_clib
PUBLIC _zx_font8
EXTERN zx__font8_data
EXTERN ts_font8_draw

_zx_font8:
        ZX_FONT8_DESCRIPTOR zx__font8_data,ts_font8_draw,0
