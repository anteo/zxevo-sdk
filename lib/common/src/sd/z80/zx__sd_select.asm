        MODULE zx__sd_select
SECTION code_clib
PUBLIC _zx__sd_select

; Set active-low CS at 0077h or 8057h as selected by the transaction.
; SDCC transaction pointer at SP+2, selected byte (0 or 1) at SP+4.
; Caller keeps decoding stable. Preserve DE/IX/IY, clobber AF/BC/HL.
_zx__sd_select:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld a,3
        sub (hl)
        sub (hl)                     ; 3 when deselected, 1 when selected
        ld h,b
        ld l,c
        inc hl
        ld b,(hl)
        ld c,77h
        bit 7,b
        jr z,@write
        ld c,57h
@write:
        out (c),a
        ret
