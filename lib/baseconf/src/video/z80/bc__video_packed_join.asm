IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
        MODULE bc__video_packed_join
SECTION code_clib
PUBLIC bc__video_packed_join

; Forms a packed pair from the right pixel of the first byte and the left
; pixel of the second byte.
;
; C model:
;
; return pack(right(first), left(second));
;
; A = first pair, E = second pair -> A = joined pair.
; Preserve DE/HL/IX/IY; clobber AF/BC.
; Left pixel bits are 0,1,2,6; right pixel bits are 3,4,5,7.
; Move those fields directly, without expanding colors into a pixel buffer.
bc__video_packed_join:
        ld b,a
        rrca
        rrca
        rrca
        and 7
        ld c,a
        ld a,b
        and 80h
        rrca
        or c
        ld c,a
        ld a,e
        and 7
        rlca
        rlca
        rlca
        or c
        ld c,a
        ld a,e
        and 40h
        rlca
        or c
        ret
ENDIF
