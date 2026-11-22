        MODULE zx_draw_line_op
EXTERN zx__graphics_line_op_a
SECTION code_graphics
PUBLIC _zx_draw_line_op

; Load the SDCC operation byte into A and tail-enter the line renderer.
_zx_draw_line_op:
IFDEF TSCONF_VIDEO_BITMAP
        ld hl,10
        add hl,sp
        ld a,(hl)
ENDIF
        jp zx__graphics_line_op_a
