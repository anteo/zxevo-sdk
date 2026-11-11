        MODULE zx_draw_ellipse
SECTION code_graphics
PUBLIC _zx_draw_ellipse
EXTERN zx__graphics_ellipse_op_a

; SDCC caller-clean coordinates. Tail-enter the ellipse with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_ellipse:
        xor a
        jp zx__graphics_ellipse_op_a
