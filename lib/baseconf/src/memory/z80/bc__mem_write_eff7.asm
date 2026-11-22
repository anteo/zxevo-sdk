        MODULE bc__mem_write_eff7
EXTERN bc__mem_write_eff7_regs
SECTION code_clib
PUBLIC _bc__mem_write_eff7

; Pass the byte at SP+2 to the EFF7 writer in E.
_bc__mem_write_eff7:
        ld hl,2
        add hl,sp
        ld e,(hl)
        jp bc__mem_write_eff7_regs
