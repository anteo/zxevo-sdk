IFDEF BASECONF_VIDEO_MODE_LINEAR
        MODULE bc__video_row_offset_40
SECTION code_clib
PUBLIC bc__video_row_offset_40
IFDEF BASECONF_VIDEO_PRIMITIVE_LINEAR
PUBLIC bc__video_line_linear_row

; Axis frame IX+6 holds the clipped row (0..199). Enter the same arithmetic.
bc__video_line_linear_row:
        ld a,(ix+6)
ENDIF

; Converts an ATM scanline number into a byte offset from the start of its
; plane.
;
; C model:
;
; return (uint16_t)y * 40;
;
; y is an in-range ATM row (0..199).
; A = y -> HL = row offset. Preserve DE/IX/IY; clobber AF/BC.
bc__video_row_offset_40:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld b,h
        ld c,l
        add hl,hl
        add hl,hl
        add hl,bc
        ret
ENDIF
