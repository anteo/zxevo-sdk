        MODULE zx_console_puts
SECTION code_clib
PUBLIC _zx_console_puts
EXTERN zx__console_puts_backend

; Validate the string before sending it to the console backend.
; Fastcall HL=string. Status in L. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_console_puts:
        ld a,h
        or l
        jr z,@invalid
        ld a,(hl)
        or a
        jp nz,zx__console_puts_backend
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
