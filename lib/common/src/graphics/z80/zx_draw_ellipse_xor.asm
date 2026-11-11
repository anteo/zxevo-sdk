        MODULE zx_draw_ellipse_xor
SECTION code_graphics
PUBLIC _zx_draw_ellipse_xor
EXTERN zx__graphics_ellipse_op_a

; SDCC caller-clean coordinates. Tail-enter the ellipse with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_ellipse_xor:
        ld a,2
        jp zx__graphics_ellipse_op_a
