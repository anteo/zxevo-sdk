        MODULE bc_clear_execution_trap
SECTION code_clib
PUBLIC _bc_clear_execution_trap

; Clear BF bit 4, retaining the programmed trap address and other BF bits.
; SDCC no arguments, return ZX_OK in L. Preserve DE/H/IX/IY, clobber AF/BC/L.
_bc_clear_execution_trap:
        ld bc,00BFh
        in a,(c)
        and 0EFh
        out (c),a
        ld l,0                       ; ZX_OK
        ret
