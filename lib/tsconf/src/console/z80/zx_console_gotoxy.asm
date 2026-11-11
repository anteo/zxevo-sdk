        MODULE zx_console_gotoxy
SECTION code_clib
PUBLIC _zx_console_gotoxy
EXTERN ts_draw_config
EXTERN ts_console_position
EXTERN ts_console_size
EXTERN zx__console_in_bounds

; Change the cursor only inside the selected grid.
; SDCC column at SP+2, row at SP+3. L=status. Preserve IX/IY.
_zx_console_gotoxy:
        ld a,(ts_draw_config)
        cp 0ffh
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld de,(ts_console_size)
        call zx__console_in_bounds
        jr nc,@invalid
        ld (ts_console_position),bc
        ld l,0
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
