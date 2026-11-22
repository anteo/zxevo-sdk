        MODULE zx__draw_font5_cell

SECTION code_clib
PUBLIC zx__draw_font5_cell
EXTERN zx__attribute_address
EXTERN zx__draw_font5_rows

; Draw an opaque 5x8 glyph and write the attribute of each cell it touches.
;
; draw_rows(glyph, bitmap, shift);
; attr = zx__attribute_address(bitmap);
; attr[0] = color; if (shift >= 4) attr[1] = color;
;
; HL=glyph, DE=first bitmap byte in a mapped 16 KiB window, A=shift 0/2/4/6,
; C=ZX attribute. Glyph fits the bitmap and starts on an eight-scanline boundary.
; Save the start address, shift and color across the row writer. AF/BC/DE/HL
; volatile, IX/IY preserved.
zx__draw_font5_cell:
        push de
        ld b,a
        push bc
        call zx__draw_font5_rows
        pop bc
        pop hl
        call zx__attribute_address
        ex de,hl
        ld (hl),c
        ld a,b
        cp 4
        ret c
        inc hl
        ld (hl),c
        ret
