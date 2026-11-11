        MODULE zx__draw_cell
SECTION code_clib
PUBLIC zx__draw_cell
EXTERN zx__cell_bitmap_address
EXTERN zx__attribute_address

; Write all eight glyph rows and the attribute of one ZX character cell.
;
; bitmap = zx__cell_bitmap_address(screen,row,column);
; *zx__attribute_address(bitmap) = attr;
; for (r=0; r<8; ++r) bitmap[256*r] = glyph[r];
;
; HL=glyph[8], B=row 0..23, C=column 0..31, D=aligned window high byte,
; A=ZX attribute. Caller keeps source and writable screen accessible.
; Preserve IX/IY, clobber AF/BC/DE/HL. Save glyph and attribute on stack.
zx__draw_cell:
        push hl
        push af
        call zx__cell_bitmap_address
        ex de,hl
        call zx__attribute_address
        pop af
        ld (de),a
        ex de,hl
        pop hl
        ld b,8
@row:
        ld a,(hl)
        inc hl
        ld (de),a
        inc d
        djnz @row
        ret
