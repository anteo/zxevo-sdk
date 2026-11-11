        MODULE bc__video_hline_span
SECTION code_clib
PUBLIC bc__video_hline_span
EXTERN bc__video_line_shift_x

; HL = row/plane CPU origin, A = x shift (3 or 4).
; IX x0 +4, x1 +8. Return HL = first byte, DE = last byte.
;
; Converts clipped horizontal endpoints into the first and last CPU byte
; addresses for the selected row or plane.
;
; Model:
;
; first=origin+(x0>>shift); last=origin+(x1>>shift);
;
; Inputs above use the normalized IX frame. AF/BC/DE/HL volatile, IX/IY
; preserved; returned endpoints are inclusive and may be empty after a backend
; rounds their physical plane parity.
bc__video_hline_span:
        push hl
        ld c,a
        ld e,(ix+4)
        ld d,(ix+5)
        ld b,c
        call bc__video_line_shift_x
        add hl,de
        ex de,hl
        pop hl
        push de
        ld e,(ix+8)
        ld d,(ix+9)
        ld b,c
        call bc__video_line_shift_x
        add hl,de
        ex de,hl
        pop hl
        ret
