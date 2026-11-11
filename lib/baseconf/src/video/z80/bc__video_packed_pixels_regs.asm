        MODULE bc__video_packed_pixels_regs
SECTION code_clib
PUBLIC bc__video_packed_pixels_regs

; E = left/ink, D = right/paper. Return A; preserve BC/DE/HL/IX/IY.
;
; Packs two four-bit colors into one byte, keeping their brightness bits
; independent.
;
; Model:
;
; return (left&7)|((left&8)<<3)|((right&7)<<3)|((right&8)<<4);
;
; Each four-bit index is permuted into disjoint physical fields (47h/B8h).
; The same layout represents ATM640 ink/paper attributes. Only AF changes;
; all other registers are preserved as documented above.
bc__video_packed_pixels_regs:
        push bc
        ld a,e
        and 7
        bit 3,e
        jr z,@left
        or 40h
@left:
        ld c,a
        ld a,d
        and 7
        rlca
        rlca
        rlca
        or c
        bit 3,d
        jr z,@done
        or 80h
@done:
        pop bc
        ret
