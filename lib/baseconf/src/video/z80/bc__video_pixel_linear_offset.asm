IFDEF BASECONF_VIDEO_MODE_LINEAR
        MODULE bc__video_pixel_linear_offset
SECTION code_clib
PUBLIC bc__video_pixel_linear_offset
EXTERN bc__video_row_offset_40

; Compute the offset of an ATM pixel group within a 40-byte-wide plane.
;
; return y*40+(x>>shift);
;
; HL=x, DE=y, B=shift (3 or 4), coordinates already in range. Return
; HL=offset and A=low byte of x for page, plane and pixel selection.
; Preserve IX/IY, clobber BC/DE and flags. Save X low on the stack.
bc__video_pixel_linear_offset:
        ld a,l
        push af
@shift:
        srl h
        rr l
        djnz @shift
        ex de,hl
        ld a,l
        call bc__video_row_offset_40
        add hl,de
        pop af
        ret
ENDIF
