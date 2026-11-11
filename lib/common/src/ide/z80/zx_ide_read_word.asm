        MODULE zx_ide_read_word
SECTION code_clib
PUBLIC _zx_ide_read_word

; Read the low byte first and store the complete IDE word in the destination.
;
; if (!value) return ZX_INVALID_ARGUMENT;
; lo = in(io_address); hi = in(io_address + 1);
; *value = lo | (hi << 8);
; return ZX_OK;
;
; SDCC port at SP+2, value pointer at SP+4, status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_ide_read_word:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        jr z,@invalid
        in l,(c)
        inc bc
        in h,(c)
        ex de,hl
        ld (hl),e
        inc hl
        ld (hl),d
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
