        MODULE bc_get_atm_rgb444_enabled
SECTION code_clib
PUBLIC _bc_get_atm_rgb444_enabled

; Return the live BF.5 bit in L as 0 or 1. Clobber AF/BC/HL.
_bc_get_atm_rgb444_enabled:
        ld bc,00BFh
        in a,(c)
        rlca
        rlca
        rlca
        and 1
        ld l,a
        ret
