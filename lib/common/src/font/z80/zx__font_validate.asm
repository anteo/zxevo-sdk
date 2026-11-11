        MODULE zx__font_validate
SECTION code_clib
PUBLIC zx__font_validate

; Validate an eight-byte bitmap font descriptor and return its advance.
;
; valid = font && font->glyphs && width in 1..8 && height in 1..8
;         && advance >= width && font->draw;
;
; HL=descriptor. Return NZ with DE=descriptor and B=advance, or Z if invalid.
; AF/BC/DE/HL volatile, IX/IY preserved. The caller owns descriptor storage.
zx__font_validate:
        ld a,h
        or l
        ret z
        ld d,h
        ld e,l
        ld c,(hl)
        inc hl
        ld a,(hl)
        or c
        ret z
        inc hl
        ld c,(hl)
        ld a,c
        dec a
        cp 8
        jr nc,@invalid
        inc hl
        ld a,(hl)
        dec a
        cp 8
        jr nc,@invalid
        inc hl
        ld a,(hl)
        cp c
        jr c,@invalid
        ld b,a
        inc hl
        inc hl
        ld c,(hl)
        inc hl
        ld a,(hl)
        or c
        ret
@invalid:
        xor a
        ret
