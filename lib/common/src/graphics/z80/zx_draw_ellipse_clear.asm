        MODULE zx_draw_ellipse_clear
SECTION code_graphics
PUBLIC _zx_draw_ellipse_clear
EXTERN zx__graphics_ellipse_op_a

; SDCC caller-clean coordinates. Tail-enter the ellipse with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_ellipse_clear:
        ld a,1
        jp zx__graphics_ellipse_op_a
