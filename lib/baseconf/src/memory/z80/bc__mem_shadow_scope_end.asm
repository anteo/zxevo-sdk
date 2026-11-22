        MODULE bc__mem_shadow_scope_end
EXTERN bc__mem_shadow_scope_end_regs
SECTION code_clib
PUBLIC _bc__mem_shadow_scope_end

; Restore BF only if scope entry changed it. SDCC fastcall saved BF in L.
; Register entry takes saved BF in A. Preserve DE/HL/IX/IY, clobber AF/BC.
_bc__mem_shadow_scope_end:
        ld a,l
        jp bc__mem_shadow_scope_end_regs
