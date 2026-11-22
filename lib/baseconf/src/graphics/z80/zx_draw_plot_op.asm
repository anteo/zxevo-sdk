        MODULE zx_draw_plot_op
EXTERN zx__graphics_plot_op_a
SECTION code_graphics
PUBLIC _zx_draw_plot_op

; Load the SDCC operation byte into A and tail-enter the plot renderer.
_zx_draw_plot_op:
        ld hl,6
        add hl,sp
        ld a,(hl)
        jp zx__graphics_plot_op_a
