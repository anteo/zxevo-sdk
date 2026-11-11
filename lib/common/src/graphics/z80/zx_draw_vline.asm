        MODULE zx_draw_vline
SECTION code_graphics
PUBLIC _zx_draw_vline
EXTERN zx__graphics_vline_op_a

; SDCC caller-clean coordinates. Tail-enter the primitive with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_vline:
        xor a
        jp zx__graphics_vline_op_a
