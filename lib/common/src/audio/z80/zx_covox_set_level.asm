SECTION code_clib
PUBLIC _zx_covox_set_level

; Write one unsigned 8-bit level to the Covox port.
; SDCC caller-clean: level at SP+2. AF/BC/HL volatile; IX/IY preserved.
_zx_covox_set_level:
        ld hl,2
        add hl,sp
        ld a,(hl)
        ld bc,$00fb
        out (c),a
        ret
