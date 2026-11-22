        MODULE zx_draw_ellipse_op
EXTERN zx__graphics_ellipse_op_a
IFDEF TSCONF_VIDEO_BITMAP
SECTION code_graphics
PUBLIC _zx_draw_ellipse_op

; Load the SDCC operation byte into A and tail-enter the ellipse renderer.
_zx_draw_ellipse_op:
        ld hl,10
        add hl,sp
        ld a,(hl)
        jp zx__graphics_ellipse_op_a
ELSE
PUBLIC _zx_draw_ellipse_op
defc _zx_draw_ellipse_op = zx__graphics_ellipse_op_a
ENDIF
