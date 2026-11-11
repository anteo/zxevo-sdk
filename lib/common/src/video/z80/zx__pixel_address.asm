        MODULE zx__pixel_address
SECTION code_graphics
PUBLIC zx__pixel_address
EXTERN zx__bitmap_offset
EXTERN zx__masks

; Find the byte and mask of one pixel in a mapped ZX bitmap.
;
; address = base | bitmap_offset(y, x >> 3); mask = 0x80 >> (x & 7);
;
; HL=x, DE=y in 256x192 bounds, A=aligned CPU window high byte.
; Return HL=bitmap address, A=mask. AF/BC/DE/HL volatile, IX/IY preserved.
; Save the mask index across the row address calculation.
zx__pixel_address:
        ld d,a
        ld a,l
        and 7
        push af
        ld a,l
        rrca
        rrca
        rrca
        and 31
        ld c,e
        ld e,a
        call zx__bitmap_offset
        ex de,hl
        pop af
        ld c,a
        ld b,0
        ld hl,zx__masks
        add hl,bc
        ld a,(hl)
        ex de,hl
        ret
