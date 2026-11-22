        MODULE ts__fdd_register_port
SECTION code_clib
PUBLIC ts__fdd_register_port

; A = 0..3. Rotate the register index into A5/A6 and add 1Fh.
; Return BC = FF1Fh, FF3Fh, FF5Fh or FF7Fh. Preserve DE/HL.
; VG93 decodes the low byte. FFh avoids the Fuller Audio Box aliases.
ts__fdd_register_port:
        rrca
        rrca
        rrca
        or 1Fh
        ld c,a
        ld b,0ffh
        ret
