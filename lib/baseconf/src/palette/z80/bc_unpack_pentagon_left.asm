        MODULE bc_unpack_pentagon_left
SECTION code_clib
PUBLIC _bc_unpack_pentagon_left

; Decode the left pixel. Its high bit is stored in bit 6 of the pair byte.
; Model:
;
; return (packed & 7) | ((packed >> 3) & 8);
;
; SDCC packed:8 at SP+2, result in L. Preserve B/DE/IX/IY, clobber AF/C/HL.
_bc_unpack_pentagon_left:
        ld hl,2
        add hl,sp
        ld c,(hl)
        ld a,c
        and 7
        ld l,a
        bit 6,c
        ret z
        set 3,l
        ret
