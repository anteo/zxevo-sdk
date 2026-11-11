        MODULE bc__mem_write_shadow_override
SECTION code_clib
PUBLIC _bc__mem_write_shadow_override

; Write only BF.0, preserving the current values of the other bits.
; SDCC fastcall L = 0 or 1. Preserve DE/HL/IX/IY, clobber AF/BC.
_bc__mem_write_shadow_override:
        ld bc,00BFh
        in a,(c)
        and 0FEh
        or l
        out (c),a
        ret
