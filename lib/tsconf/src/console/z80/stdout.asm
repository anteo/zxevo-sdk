        MODULE ts_console_stdout
SECTION code_clib
PUBLIC fputc_cons_native
EXTERN ts_console_putc_a

; z88dk classic console hook. Character byte at SP+2. Preserve IX/IY.
fputc_cons_native:
        ld hl,2
        add hl,sp
        ld a,(hl)
        jp ts_console_putc_a
