        MODULE zx__font_rows_from_frame

SECTION code_clib
PUBLIC zx__font_rows_from_frame
EXTERN zx__font_rows

; IX = font callback frame after saving IX: x +4, y +6, font +8,
; code +10, ink +11, paper +12. Return HL = font->glyphs + glyph*8.
; Codes outside 32..127 use '?'. Preserve IX/IY; clobber AF/DE/HL.
;
; Load the font and code from the callback frame for the common lookup.
zx__font_rows_from_frame:
        ld l,(ix+8)
        ld h,(ix+9)
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,(ix+10)
        jp zx__font_rows
