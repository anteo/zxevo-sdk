        MODULE zx_draw_plot_xor
SECTION code_graphics
PUBLIC _zx_draw_plot_xor
EXTERN zx__graphics_plot_op_a

; SDCC caller-clean coordinates. Tail-enter the primitive with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_plot_xor:
        ld a,2
        jp zx__graphics_plot_op_a
