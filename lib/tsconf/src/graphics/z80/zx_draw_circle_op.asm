        MODULE zx_draw_circle_op
EXTERN zx__graphics_circle_op_a
SECTION code_graphics
PUBLIC _zx_draw_circle_op

; Load the SDCC operation byte into A and tail-enter the circle renderer.
_zx_draw_circle_op:
IFDEF TSCONF_VIDEO_BITMAP
        ld hl,8
        add hl,sp
        ld a,(hl)
ENDIF
        jp zx__graphics_circle_op_a
