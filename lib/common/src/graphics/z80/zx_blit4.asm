        MODULE zx_blit4
SECTION code_graphics
PUBLIC _zx_blit4
EXTERN zx__blit4

; Copy opaque 4bpp pixels. SDCC caller-clean descriptor/x/y at SP+2/+4/+6.
; FFh cannot match a 4-bit source index. Common entry preserves IX/IY.
_zx_blit4:
        ld a,0ffh
        jp zx__blit4
