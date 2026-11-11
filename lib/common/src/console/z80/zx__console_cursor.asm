        MODULE zx__console_cursor
SECTION code_clib
PUBLIC zx__console_control
PUBLIC zx__console_advance
PUBLIC zx__console_newline
PUBLIC zx__console_in_bounds

; Apply CR, LF or BS. Other controls leave the cursor unchanged.
; A=code, BC=column/row, D=rows. Return cursor in BC. Clobber AF only.
zx__console_control:
        cp 10
        jr z,zx__console_newline
        cp 13
        jr z,@carriage_return
        cp 8
        ret nz
        ld a,c
        or a
        ret z
        dec c
        ret
@carriage_return:
        ld c,0
        ret

; Advance one cell and wrap at the right edge.
; BC=column/row, DE=columns/rows, both dimensions nonzero.
; Return cursor in BC. Clobber AF only.
zx__console_advance:
        inc c
        ld a,c
        cp e
        ret c

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

; Return carry when BC=column/row is inside DE=columns/rows.
; AF volatile. Preserve BC/DE/HL/IX/IY.
zx__console_in_bounds:
        ld a,c
        cp e
        ret nc
        ld a,b
        cp d
        ret
