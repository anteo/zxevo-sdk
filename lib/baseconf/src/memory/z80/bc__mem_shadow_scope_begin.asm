        MODULE bc__mem_shadow_scope_begin
EXTERN _bc__mem_shadow_scope_open
SECTION code_clib
PUBLIC _bc__mem_shadow_scope_begin

; Save BF in L and set its shadow override bit for a temporary scope.
; The fastcall entry takes an already sampled BF in L. Both preserve DE/H/IX/IY
; and clobber AF/BC. Neither changes the interrupt state.
_bc__mem_shadow_scope_begin:
        ld bc,00BFh
        in l,(c)
        jp _bc__mem_shadow_scope_open
