        MODULE zx_set_paper
SECTION code_clib
PUBLIC _zx_set_paper
EXTERN zx__paper

; Store the supplied background index byte for later drawing.
; SDCC index:8 at SP+2, void result. Preserve BC/DE/IX/IY, clobber AF/HL.
_zx_set_paper:
        ld hl,2
        add hl,sp
        ld a,(hl)
        ld (zx__paper),a
        ret
