        MODULE zx__console_newline
SECTION code_clib
PUBLIC zx__console_newline

; Move to the first column of the next row, staying at the bottom row.
;
; column = 0; row = min((uint8_t)(row+1), rows-1);
;
; BC=column/row, D=rows (nonzero). Return cursor in BC. Clobber AF only.
zx__console_newline:
        ld c,0
        ld a,b
        inc a
        cp d
        jr c,@store_row
        ld a,d
        dec a
@store_row:
        ld b,a
        ret
