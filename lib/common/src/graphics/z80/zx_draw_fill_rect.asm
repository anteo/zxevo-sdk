        MODULE zx_draw_fill_rect
SECTION code_graphics
PUBLIC _zx_draw_fill_rect
EXTERN zx__graphics_rect_a

; SDCC caller-clean x/y/width/height. Tail-enter with SET in A.
_zx_draw_fill_rect:
        xor a
        jp zx__graphics_rect_a
