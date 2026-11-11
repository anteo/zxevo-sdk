        MODULE zx_draw_circle_op
SECTION code_graphics
PUBLIC _zx_draw_circle_op
PUBLIC zx__graphics_circle_op_a
IFDEF TSCONF_VIDEO_BITMAP
EXTERN zx__graphics_ellipse_op_a
ENDIF

; Draw a circle using equal ellipse semi-axes.
;
; ellipse(cx, cy, radius, radius, operation);
;
; SDCC cx/cy/radius words at SP+2/+4/+6 and operation at SP+8.
; The shorthand entry takes the operation in A.
; IX anchors the original frame and the ellipse arguments are pushed below.
_zx_draw_circle_op:
IFDEF TSCONF_VIDEO_BITMAP
        ld hl,8
        add hl,sp
        ld a,(hl)
ENDIF
zx__graphics_circle_op_a:
IFDEF TSCONF_VIDEO_BITMAP
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+8)
        ld h,(ix+9)
        push hl
        push hl
        ld l,(ix+6)
        ld h,(ix+7)
        push hl
        ld l,(ix+4)
        ld h,(ix+5)
        push hl
        call zx__graphics_ellipse_op_a
        ld sp,ix
        pop ix
ENDIF
        ret
