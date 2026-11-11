        MODULE zx_draw_vline_op
SECTION code_graphics
PUBLIC _zx_draw_vline_op
PUBLIC zx__graphics_vline_op_a
IFDEF TSCONF_VIDEO_BITMAP
EXTERN zx__graphics_line_op_a
ENDIF

; Draw a clipped axis span through the TSConf line renderer.
;
; line(x, y0, x, y1, operation);
;
; SDCC x/y0/y1 at SP+2/+4/+6, operation at SP+8. Shorthands pass
; the operation in A. IX anchors the original frame. The line receives
; four coordinate words on the stack and the operation in A.
_zx_draw_vline_op:
IFDEF TSCONF_VIDEO_BITMAP
        ld hl,8
        add hl,sp
        ld a,(hl)
ENDIF
zx__graphics_vline_op_a:
IFDEF TSCONF_VIDEO_BITMAP
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+8)
        ld h,(ix+9)
        push hl
        ld e,(ix+4)
        ld d,(ix+5)
        push de
        ld l,(ix+6)
        ld h,(ix+7)
        push hl
        push de
        call zx__graphics_line_op_a
        ld sp,ix
        pop ix
ENDIF
        ret
