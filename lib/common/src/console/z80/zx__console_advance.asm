        MODULE zx__console_advance
EXTERN zx__console_newline
SECTION code_clib
PUBLIC zx__console_advance

; Advance one cell and wrap at the right edge.
; BC=column/row, DE=columns/rows, both dimensions nonzero.
; Return cursor in BC. Clobber AF only.
zx__console_advance:
        inc c
        ld a,c
        cp e
        ret c
        jp zx__console_newline
