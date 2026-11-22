        MODULE zx__console_in_bounds
SECTION code_clib
PUBLIC zx__console_in_bounds

; Return carry when BC=column/row is inside DE=columns/rows.
; AF volatile. Preserve BC/DE/HL/IX/IY.
zx__console_in_bounds:
        ld a,c
        cp e
        ret nc
        ld a,b
        cp d
        ret
