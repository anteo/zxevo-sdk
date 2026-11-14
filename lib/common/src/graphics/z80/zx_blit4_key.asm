        MODULE zx_blit4_key
SECTION code_graphics
PUBLIC _zx_blit4_key
EXTERN zx__blit4

; Copy pixels except the supplied key. SDCC caller-clean descriptor/x/y/key
; at SP+2/+4/+6/+8; return status in L, preserving IX/IY.
_zx_blit4_key:
        ld hl,8
        add hl,sp
        ld a,(hl)
        cp 16
        jp c,zx__blit4
        ld l,1                      ; ZX_INVALID_ARGUMENT
        ret
