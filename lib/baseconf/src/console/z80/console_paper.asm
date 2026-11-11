        MODULE baseconf_console_paper
PUBLIC generic_console_set_paper
EXTERN zx__paper
SECTION code_clib

; A = paper. Keep the generic-console result A=L=0, Z set and carry clear.
; Setter: current_paper=A & 15; return A=L=0, Z=1, CF=0.
; No lease or mapping; AF/L volatile, H/BC/DE/IX/IY preserved.
generic_console_set_paper:
        and 15
        ld (zx__paper),a
        xor a
        ld l,a
        ret
