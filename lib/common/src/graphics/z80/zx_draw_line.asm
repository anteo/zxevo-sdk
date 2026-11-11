        MODULE zx_draw_line
SECTION code_graphics
PUBLIC _zx_draw_line
EXTERN zx__graphics_line_op_a

; SDCC caller-clean coordinates. Tail-enter the primitive with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_line:
        xor a
        jp zx__graphics_line_op_a
