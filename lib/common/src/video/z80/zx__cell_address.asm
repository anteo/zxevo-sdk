        MODULE zx__cell_address
SECTION code_clib
PUBLIC zx__cell_bitmap_address

; Locate the first raster byte of a ZX character cell.
;
; return screen | ((row & 0x18) << 8) | ((row & 7) << 5) | column;
;
; B=row 0..23, C=column 0..31, D=high byte of a 16 KiB-aligned window.
; Return DE=bitmap address. Clobber AF/DE, preserve HL/BC/IX/IY.
zx__cell_bitmap_address:
        ld a,b
        and 18h
        or d
        ld d,a
        ld a,b
        and 7
        rrca
        rrca
        rrca
        or c
        ld e,a
        ret
