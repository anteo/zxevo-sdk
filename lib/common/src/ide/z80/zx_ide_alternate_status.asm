        MODULE zx_ide_alternate_status
SECTION code_clib
PUBLIC _zx_ide_alternate_status

; Read the alternate ATA status byte from base:C8. SDCC base at SP+2,
; status pointer at SP+3, result in L. Preserve DE/IX/IY, clobber AF/BC/HL.
_zx_ide_alternate_status:
        ld hl,2
        add hl,sp
        ld b,(hl)
        inc hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        or h
        jr z,@invalid
        ld c,0C8h
        in a,(c)
        ld (hl),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
