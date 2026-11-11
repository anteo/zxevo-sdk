        MODULE ts__printf_write
SECTION code_clib
PUBLIC _zx__printf_write
EXTERN ts_console_putc_a

; Consume one character using the currently selected console surface.
;
; return console_putc(*text) == OK ? 1 : -1;
;
; SDCC caller-clean text pointer at SP+2, limit and delimiter at SP+4/+5.
; Return count or error in HL. Clobber AF/BC/DE/HL, preserve IX/IY.
_zx__printf_write:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,(de)
        call ts_console_putc_a
        ld a,l
        or a
        ld hl,1
        ret z
        ld hl,-1
        ret
