        MODULE zx_draw_hline_op
EXTERN zx__graphics_hline_op_a
SECTION code_graphics
PUBLIC _zx_draw_hline_op

; Load the SDCC operation byte into A and tail-enter the hline renderer.
_zx_draw_hline_op:
        ld hl,8
        add hl,sp
        ld a,(hl)
        cp 3
        ret nc
        jp zx__graphics_hline_op_a
