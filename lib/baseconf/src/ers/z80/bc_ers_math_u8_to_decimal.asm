        MODULE bc_ers_math_u8_to_decimal

SECTION code_clib
PUBLIC _bc_ers_math_u8_to_decimal
EXTERN _bc_ers_profile

; Writes the decimal text representation of an unsigned byte to the caller's
; buffer.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE; if (!output) return INVALID_ARGUMENT;
; ERS(0x4c, 0x06, E=value, HL=output); return OK;
;
; IX frame after PUSH IX: value +4, packed output pointer +5. Output holds 11 bytes.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_math_u8_to_decimal:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_math_u8_to_decimal_unavailable
        ld l,(ix+5)
        ld h,(ix+6)
        ld a,h
        or l
        jp z,bc_ers_math_u8_to_decimal_invalid
        ld e,(ix+4)
        rst 08h
        defb 4ch,06h
        pop ix
        ld hl,0
        ret
bc_ers_math_u8_to_decimal_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_math_u8_to_decimal_unavailable:
        pop ix
        ld hl,3
        ret
