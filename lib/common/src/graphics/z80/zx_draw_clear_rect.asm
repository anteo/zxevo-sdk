        MODULE zx_draw_clear_rect
SECTION code_graphics
PUBLIC _zx_draw_clear_rect
EXTERN zx__graphics_rect_a

; SDCC caller-clean x/y/width/height. Tail-enter with CLEAR in A.
_zx_draw_clear_rect:
        ld a,1
        jp zx__graphics_rect_a
