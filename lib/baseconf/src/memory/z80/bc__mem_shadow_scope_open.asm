        MODULE bc__mem_shadow_scope_open
SECTION code_clib
PUBLIC _bc__mem_shadow_scope_open
_bc__mem_shadow_scope_open:
        bit 0,l
        ret nz
        ld a,l
        or 1
        ld bc,00BFh
        out (c),a
        ret
