        MODULE zx__font_cell_columns
EXTERN zx__font_column_byte
EXTERN zx__font_columns
SECTION code_clib
PUBLIC zx__font_cell_columns

; Convert a nominal grid in eight-pixel cells to columns for a bitmap font.
; A=nominal columns, E=advance. Return A=min(255,nominal*8/advance).
; The caller guarantees a nonzero advance. AF/BC/DE/HL volatile, IX/IY preserved.
zx__font_cell_columns:
        ld l,a
        ld a,e
        cp 8
        ld a,l
        ret z
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        call zx__font_columns
        jp zx__font_column_byte
