        MODULE bc_readback_register

SECTION code_clib
PUBLIC _bc_readback_register
INCLUDE "memory/readback.inc"

; Read register index (SDCC byte at SP+2) through the detected FPGA port.
; Returns the byte in L. Clobbers AF/BC/HL, preserves DE/IX/IY.
_bc_readback_register:
        ld hl,2
        add hl,sp
        BC_MEM_READBACK (hl), l
        ret
