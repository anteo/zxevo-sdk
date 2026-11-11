        MODULE bc__console_newline
SECTION code_clib
PUBLIC _bc__console_newline
EXTERN __console_x
EXTERN __console_h
EXTERN zx__console_newline

; Moves the cursor to the first column of the next row, stopping at the
; bottom row.
;
; Model:
;
; cursor_x=0; cursor_y=min((uint8_t)(cursor_y+1), (uint8_t)(rows-1));
;
; No lease or scroll. Requires nonzero geometry. No arguments/results;
; AF/BC clobbered; HL/DE/IX/IY preserved.
_bc__console_newline:
        push de
        ld bc,(__console_x)
        ld a,(__console_h)
        ld d,a
        call zx__console_newline
        ld (__console_x),bc
        pop de
        ret
