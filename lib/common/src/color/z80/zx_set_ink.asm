        MODULE zx_set_ink
SECTION code_clib
PUBLIC _zx_set_ink
EXTERN zx__ink

; Store the supplied foreground index byte for later drawing.
; SDCC index:8 at SP+2, void result. Preserve BC/DE/IX/IY, clobber AF/HL.
_zx_set_ink:
        ld hl,2
        add hl,sp
        ld a,(hl)
        ld (zx__ink),a
        ret
