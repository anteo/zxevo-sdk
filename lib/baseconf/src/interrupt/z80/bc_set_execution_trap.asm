        MODULE bc_set_execution_trap
SECTION code_clib
PUBLIC _bc_set_execution_trap

; Replace the execution-trap address and update its enable bit.
;
; out(0x10bd, low(trap.address)); out(0x11bd, high(trap.address));
; out(0x00bf, (in(0x00bf) & ~0x10) | (trap.enabled ? 0x10 : 0));
;
; SDCC passes the three-byte struct by value, address at SP+2/+3 and
; enabled at SP+4. Preserve IX/IY, clobber AF/BC/D/HL. Always write both
; address bytes before modifying BF, including when disabling the trap.
_bc_set_execution_trap:
        ld hl,2
        add hl,sp
        ld bc,10BDh
        ld a,(hl)
        out (c),a
        inc hl
        inc b                        ; 11BDh
        ld a,(hl)
        out (c),a
        inc hl

        xor a
        cp (hl)                      ; carry iff enabled is nonzero
        sbc a,a
        and 10h
        ld bc,00BFh
        in d,(c)
        res 4,d
        or d
        out (c),a
        ret
