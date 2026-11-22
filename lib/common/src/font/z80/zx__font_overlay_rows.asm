        MODULE zx__font_overlay_rows

SECTION code_clib
PUBLIC zx__font_overlay_rows

; Overlay a glyph on eight aligned ZX bitmap rows, leaving attributes intact.
;
; for (row = 0; row != 8; ++row) {
;     bits = ((glyph[row] & mask) << 8) >> shift;
;     bitmap[row * 256] |= bits >> 8;
;     if ((uint8_t)bits) bitmap[row * 256 + 1] |= (uint8_t)bits;
; }
;
; HL=glyph, DE=first bitmap byte, A=shift (0..7), C=glyph mask.
; The complete glyph fits, and Y is aligned to an eight-line character row.
; AF/BC/DE/HL volatile, IX/IY preserved. Shifted rows save shift, mask and
; row count on the stack. Byte-aligned glyphs need only one bitmap byte per row.
zx__font_overlay_rows:
        ld b,8
        or a
        jr nz,@row
        ex de,hl                     ; HL=bitmap, DE=glyph
@aligned:
        ld a,(de)
        inc de
        and c
        or (hl)
        ld (hl),a
        inc h
        djnz @aligned
        ret
@row:
        push bc
        push af
        ld b,a
        ld a,(hl)
        inc hl
        and c
        ld c,0
@shift:
        srl a
        rr c
        djnz @shift
        ld b,a
        ld a,(de)
        or b
        ld (de),a
        ld a,c
        or a
        jr z,@next
        inc de
        ld a,(de)
        or c
        ld (de),a
        dec de
@next:
        inc d
        pop af
        pop bc
        djnz @row
        ret
