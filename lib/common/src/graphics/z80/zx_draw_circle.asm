        MODULE zx_draw_circle
SECTION code_graphics
PUBLIC _zx_draw_circle
EXTERN zx__graphics_circle_op_a

; SDCC caller-clean coordinates. Tail-enter the primitive with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_circle:
        xor a
        jp zx__graphics_circle_op_a
