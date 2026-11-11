        MODULE bc__mem_shadow_scope_begin
SECTION code_clib
PUBLIC _bc__mem_shadow_scope_begin
PUBLIC _bc__mem_shadow_scope_open

; Save BF in L and set its shadow override bit for a temporary scope.
; The fastcall entry takes an already sampled BF in L. Both preserve DE/H/IX/IY
; and clobber AF/BC. Neither changes the interrupt state.
_bc__mem_shadow_scope_begin:
        ld bc,00BFh
        in l,(c)
_bc__mem_shadow_scope_open:
        bit 0,l
        ret nz
        ld a,l
        or 1
        ld bc,00BFh
        out (c),a
        ret
