        MODULE bc__mem_shadow_scope_end
SECTION code_clib
PUBLIC _bc__mem_shadow_scope_end
PUBLIC bc__mem_shadow_scope_end_regs

; Restore BF only if scope entry changed it. SDCC fastcall saved BF in L.
; Register entry takes saved BF in A. Preserve DE/HL/IX/IY, clobber AF/BC.
_bc__mem_shadow_scope_end:
        ld a,l
bc__mem_shadow_scope_end_regs:
        bit 0,a
        ret nz
        ld bc,00BFh
        out (c),a
        ret
