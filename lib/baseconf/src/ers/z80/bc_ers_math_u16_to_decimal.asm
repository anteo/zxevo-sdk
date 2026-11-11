        MODULE bc_ers_math_u16_to_decimal

SECTION code_clib
PUBLIC _bc_ers_math_u16_to_decimal
EXTERN _bc_ers_profile

; Writes the decimal text representation of an unsigned 16-bit value to the
; caller's buffer.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE; if (!output) return INVALID_ARGUMENT;
; ERS(0x4c, 0x05, DE=value, HL=output); return OK;
;
; IX frame: value +4, output pointer +6. Output has 11 writable bytes.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_math_u16_to_decimal:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_math_u16_to_decimal_unavailable
        ld l,(ix+6)
        ld h,(ix+7)
        ld a,h
        or l
        jp z,bc_ers_math_u16_to_decimal_invalid
        ld e,(ix+4)
        ld d,(ix+5)
        rst 08h
        defb 4ch,05h
        pop ix
        ld hl,0
        ret
bc_ers_math_u16_to_decimal_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_math_u16_to_decimal_unavailable:
        pop ix
        ld hl,3
        ret
