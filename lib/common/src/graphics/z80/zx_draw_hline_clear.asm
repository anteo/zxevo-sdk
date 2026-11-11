        MODULE zx_draw_hline_clear
SECTION code_graphics
PUBLIC _zx_draw_hline_clear
EXTERN zx__graphics_hline_op_a

; SDCC caller-clean coordinates. Tail-enter the primitive with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_hline_clear:
        ld a,1
        jp zx__graphics_hline_op_a
