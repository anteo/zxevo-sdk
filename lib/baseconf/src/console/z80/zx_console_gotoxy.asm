        MODULE zx_console_gotoxy
SECTION code_clib
PUBLIC _zx_console_gotoxy
EXTERN __console_x
EXTERN __console_w
EXTERN zx__console_in_bounds

; SDCC column:8, row:8. Return ZX_OK or ZX_INVALID_ARGUMENT in L.
;
; Moves the console cursor within the grid maintained by surface and font
; selection.
;
; Model:
;
; if (column>=columns || row>=rows) return INVALID_ARGUMENT;
; cursor_x=column; cursor_y=row; return OK;
;
; No video lease is acquired. Return byte status in L; AF/BC/DE/HL volatile,
; IX/IY preserved; invalid coordinates do not alter the cursor.
_zx_console_gotoxy:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld de,(__console_w)
        call zx__console_in_bounds
        jr nc,@invalid
        ld (__console_x),bc
        ld l,0
        ret
@invalid:
        ld l,1
        ret
