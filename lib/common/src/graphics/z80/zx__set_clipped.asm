        MODULE zx__set_clipped
SECTION code_graphics
PUBLIC zx__set_clipped
EXTERN zx__set

; Set a pixel only inside the standard ZX bitmap.
; HL=x, DE=y, A=aligned CPU window high byte. Preserve IX/IY.
zx__set_clipped:
        ld c,a
        ld a,h
        or d
        ret nz
        ld a,e
        cp 192
        ret nc
        ld a,c
        jp zx__set
