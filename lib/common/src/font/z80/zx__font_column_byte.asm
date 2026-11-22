        MODULE zx__font_column_byte
SECTION code_clib
PUBLIC zx__font_column_byte

; Saturate the whole-column count in HL to the byte used by console cursors.
; Return A. Preserve BC/DE/HL/IX/IY.
zx__font_column_byte:
        ld a,h
        or a
        ld a,l
        ret z
        ld a,255
        ret
