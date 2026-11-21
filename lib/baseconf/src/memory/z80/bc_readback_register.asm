        MODULE bc_readback_register

SECTION code_clib
PUBLIC _bc_readback_register
PUBLIC bc__mem_readback_register_regs
EXTERN _bc_mem_readback_port

; SDCC caller-clean ABI: index is at SP+2. Register entry takes B = index.
; Read register index through the selected readback port:
;
; return IN((index<<8) | readback_port);
;
; Both entries return the byte in L. AF/BC/HL volatile, DE/IX/IY preserved.
; zx_init detects the low port byte (BD or BE).
_bc_readback_register:
        ld hl,2
        add hl,sp
        ld b,(hl)
bc__mem_readback_register_regs:
        ld a,(_bc_mem_readback_port)
        ld c,a
        in l,(c)
        ret
