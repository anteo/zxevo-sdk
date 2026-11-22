        MODULE zx__font_columns
SECTION code_clib
PUBLIC zx__font_columns

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
