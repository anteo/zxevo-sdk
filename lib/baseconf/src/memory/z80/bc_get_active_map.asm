        MODULE bc_get_active_map
SECTION code_clib
PUBLIC _bc_get_active_map
EXTERN bc__mem_readback_register_regs

; Return the live 7FFD map bit in L (BC_MAP_0 or BC_MAP_1).
; Z is set for map 0 and clear for map 1. Preserve DE/IX/IY, clobber AF/BC/HL.
_bc_get_active_map:
        ld b,0Ah
        call bc__mem_readback_register_regs
        bit 4,l
        ld l,0
        ret z
        inc l
        ret
