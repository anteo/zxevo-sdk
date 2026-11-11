        MODULE zx_draw_plot
SECTION code_graphics
PUBLIC _zx_draw_plot
EXTERN zx__graphics_plot_op_a

; SDCC caller-clean coordinates. Tail-enter the primitive with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_plot:
        xor a
        jp zx__graphics_plot_op_a
