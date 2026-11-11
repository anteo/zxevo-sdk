        MODULE zx_console_get_size
SECTION code_clib
PUBLIC _zx_console_get_size
EXTERN ts_draw_config
EXTERN ts_console_size

; Return the selected console grid in columns and rows.
; Fastcall HL=output (column count, row count), L=status. Leave output
; unchanged without a surface. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_console_get_size:
        ld a,h
        or l
        jr z,@invalid
        ld a,(ts_draw_config)
        cp 0ffh
        jr z,@unselected
        ld de,(ts_console_size)
        ld (hl),e
        inc hl
        ld (hl),d
        ld l,0
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@unselected:
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret
