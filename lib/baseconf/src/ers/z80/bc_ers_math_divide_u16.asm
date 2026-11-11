        MODULE bc_ers_math_divide_u16

SECTION code_clib
PUBLIC _bc_ers_math_divide_u16
EXTERN _bc_ers_profile

; Stores the unsigned quotient of two 16-bit values.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE; if (!quotient) return INVALID_ARGUMENT;
; ERS(0x4c, 0x00, HL=dividend, DE=divisor); *quotient = DE; return OK;
;
; IX frame: dividend +4, divisor +6, quotient pointer +8. Divisor must be
; nonzero; the wrapper does not test it. Only the returned quotient is stored.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_math_divide_u16:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_math_divide_u16_unavailable
        ld l,(ix+8)
        ld h,(ix+9)
        ld a,h
        or l
        jp z,bc_ers_math_divide_u16_invalid
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        rst 08h
        defb 4ch,00h
        ld l,(ix+8)
        ld h,(ix+9)
        ld (hl),e
        inc hl
        ld (hl),d
        pop ix
        ld hl,0
        ret
bc_ers_math_divide_u16_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_math_divide_u16_unavailable:
        pop ix
        ld hl,3
        ret
