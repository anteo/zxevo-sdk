        MODULE bc_newirq_acknowledge
SECTION code_clib
PUBLIC _bc_newirq_acknowledge
EXTERN _bc_newirq_enabled

; Clear the selected request bits at 16BDh with D7 clear.
; SDCC mask at SP+2, status in L. Preserve DE/IX/IY, clobber AF/BC/HL.
_bc_newirq_acknowledge:
        ld a,(_bc_newirq_enabled)
        or a
        ld l,3                       ; ZX_UNAVAILABLE
        ret z
        ld hl,2
        add hl,sp
        ld a,(hl)
        or a
        ld l,1                       ; ZX_INVALID_ARGUMENT if D7 was set
        ret m
        ld bc,16BDh
        out (c),a
        ld l,0                       ; ZX_OK
        ret
