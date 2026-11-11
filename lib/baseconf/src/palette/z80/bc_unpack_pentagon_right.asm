        MODULE bc_unpack_pentagon_right
SECTION code_clib
PUBLIC _bc_unpack_pentagon_right

; Decode the right pixel. Bits 5:3 hold its low bits and bit 7 holds its high bit.
; Model:
;
; return ((packed >> 3) & 7) | ((packed >> 4) & 8);
;
; SDCC packed:8 at SP+2, result in L. Preserve B/DE/IX/IY, clobber AF/C/HL.
_bc_unpack_pentagon_right:
        ld hl,2
        add hl,sp
        ld c,(hl)
        ld a,c
        rrca
        rrca
        rrca
        and 7
        ld l,a
        bit 7,c
        ret z
        set 3,l
        ret
