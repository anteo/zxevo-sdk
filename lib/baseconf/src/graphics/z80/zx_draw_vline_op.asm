        MODULE zx_draw_vline_op
EXTERN zx__graphics_vline_op_a
SECTION code_graphics
PUBLIC _zx_draw_vline_op

; Load the SDCC operation byte into A and tail-enter the vline renderer.
_zx_draw_vline_op:
        ld hl,8
        add hl,sp
        ld a,(hl)
        cp 3
        ret nc
        jp zx__graphics_vline_op_a
