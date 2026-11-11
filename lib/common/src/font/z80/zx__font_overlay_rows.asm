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
; AF/BC/DE/HL volatile, IX/IY preserved. Stack saves shift, mask and row count.
zx__font_overlay_rows:
        ld b,8
@row:
        push bc
        push af
        ld b,a
        ld a,(hl)
        inc hl
        and c
        ld c,0
        inc b
        jr @shift_test
@shift:
        srl a
        rr c
@shift_test:
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
