        MODULE zx_draw_plot_clear
SECTION code_graphics
PUBLIC _zx_draw_plot_clear
EXTERN zx__graphics_plot_op_a

; SDCC caller-clean coordinates. Tail-enter the primitive with a fixed
; operation in A. Preserve IX/IY.
_zx_draw_plot_clear:
        ld a,1
        jp zx__graphics_plot_op_a
