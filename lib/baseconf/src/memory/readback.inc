EXTERN _bc_mem_readback_port

; Read FPGA register index into result (an 8-bit register) using the port
; selected by zx_init. Clobbers AF/BC and result, uses no stack.
        MACRO BC_MEM_READBACK index, result
        ld b,index
        ld a,(_bc_mem_readback_port)
        ld c,a
        in result,(c)
        ENDM
