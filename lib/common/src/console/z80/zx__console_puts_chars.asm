        MODULE zx__console_puts_chars
SECTION code_clib
PUBLIC zx__console_puts_chars
EXTERN _zx_console_putc

; Feed a string to the regular cursor-based character writer.
;
; while (*text) { status = putc(*text++); if (status != OK) return status; }
; return OK;
;
; HL=valid string. Preserve IX/IY. Status in L. The saved pointer is separate
; from the one-byte SDCC argument, which the callee can change.
zx__console_puts_chars:
        ld a,(hl)
        or a
        jr z,@done
        inc hl
        push hl
        push af
        inc sp
        call _zx_console_putc
        inc sp
        pop de
        ld a,l
        or a
        ret nz
        ex de,hl
        jr zx__console_puts_chars
@done:
        ld l,0                       ; ZX_OK
        ret
