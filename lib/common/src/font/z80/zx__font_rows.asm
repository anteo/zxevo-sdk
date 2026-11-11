        MODULE zx__font_rows
SECTION code_clib
PUBLIC zx__font_rows

; Locate an eight-row glyph in a font for codes 32..127.
;
; if (code < 32 || code > 127) code = '?';
; return font + 8 * (code - 32);
;
; A=code, DE=font base. Return HL. Preserve BC/DE/IX/IY, clobber AF.
zx__font_rows:
        sub 32
        cp 96
        jr c,@glyph
        ld a,'?'-32
@glyph:
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,de
        ret
