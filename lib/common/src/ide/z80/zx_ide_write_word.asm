        MODULE zx_ide_write_word
SECTION code_clib
PUBLIC _zx_ide_write_word

; Write the high byte at port+1, then the low byte at port.
; SDCC port at SP+2, value at SP+4, ZX_OK in L. Preserve AF/IX/IY.
_zx_ide_write_word:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc bc
        out (c),d
        dec bc
        out (c),e
        ld l,0
        ret
