        MODULE baseconf_console_ink
PUBLIC generic_console_set_ink
EXTERN zx__ink
SECTION code_clib

; A = ink. Keep the generic-console result A=L=0, Z set and carry clear.
; Setter: current_ink=A & 15; return A=L=0, Z=1, CF=0.
; No lease or mapping; AF/L volatile, H/BC/DE/IX/IY preserved.
generic_console_set_ink:
        and 15
        ld (zx__ink),a
        xor a
        ld l,a
        ret
