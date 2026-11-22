        MODULE zx__graphics_hline_op_a
IFDEF TSCONF_VIDEO_BITMAP
EXTERN zx__graphics_line_op_a
ENDIF
SECTION code_graphics
PUBLIC zx__graphics_hline_op_a

; Draw a clipped axis span through the TSConf line renderer.
;
; line(x0, y, x1, y, operation);
;
; SDCC x0/x1/y at SP+2/+4/+6, operation at SP+8. Shorthands pass
; the operation in A. IX anchors the original frame. The line receives
; four coordinate words on the stack and the operation in A.
zx__graphics_hline_op_a:
IFDEF TSCONF_VIDEO_BITMAP
        push ix
        ld ix,0
        add ix,sp
        ld e,(ix+8)
        ld d,(ix+9)
        push de
        ld l,(ix+6)
        ld h,(ix+7)
        push hl
        push de
        ld l,(ix+4)
        ld h,(ix+5)
        push hl
        call zx__graphics_line_op_a
        ld sp,ix
        pop ix
ENDIF
        ret
