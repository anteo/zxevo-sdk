        MODULE bc__video_row_offset_40
IFDEF BASECONF_VIDEO_MODE_LINEAR
SECTION code_clib
PUBLIC bc__video_row_offset_40

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
