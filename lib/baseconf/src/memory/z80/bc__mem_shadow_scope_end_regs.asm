        MODULE bc__mem_shadow_scope_end_regs
SECTION code_clib
PUBLIC bc__mem_shadow_scope_end_regs
bc__mem_shadow_scope_end_regs:
        bit 0,a
        ret nz
        ld bc,00BFh
        out (c),a
        ret
