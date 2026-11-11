        MODULE baseconf_console_attribute
PUBLIC generic_console_set_attribute
SECTION code_clib

; A = attribute. Keep the generic-console result A=L=0, Z set and carry clear.
; Return A=L=0, Z=1, CF=0.
; No lease or mapping; AF/L volatile, H/BC/DE/IX/IY preserved.
generic_console_set_attribute:
        xor a
        ld l,a
        ret
