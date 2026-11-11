        MODULE zx__font_columns
SECTION code_clib
PUBLIC zx__font_columns
PUBLIC zx__font_cell_columns
PUBLIC zx__font_column_byte

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

; Saturate the whole-column count in HL to the byte used by console cursors.
; Return A. Preserve BC/DE/HL/IX/IY.
zx__font_column_byte:
        ld a,h
        or a
        ld a,l
        ret z
        ld a,255
        ret

; HL = pixel width, E = advance -> HL = number of whole columns.
; A zero advance returns zero. Preserve IX/IY, clobber AF/BC/DE.
; Independent of the video cache, selected font, and CRT division routines.
;
; Counts how many complete character advances fit in a pixel width.
;
; Model:
;
; columns=0; if (advance) while (width >= advance) { width-=advance; ++columns; }
; return columns;
;
; Pure unsigned 16/8 division by subtraction; a font advance of zero is
; handled without entering the loop. See the register ABI above.
zx__font_columns:
        ld a,e
        or a
        jr z,@zero
        ld d,0
        ld bc,0
@divide:
        or a
        sbc hl,de
        jr c,@done
        inc bc
        jr @divide
@done:
        ld h,b
        ld l,c
        ret
@zero:
        ld hl,0
        ret
