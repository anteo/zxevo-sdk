        MODULE zx_font5
INCLUDE "font/z80/zx_font.inc"
SECTION rodata_clib
PUBLIC _zx_font5
EXTERN _zx_font5_data
EXTERN ts_font5_draw

_zx_font5:
        ZX_FONT5_DESCRIPTOR _zx_font5_data,ts_font5_draw,0
