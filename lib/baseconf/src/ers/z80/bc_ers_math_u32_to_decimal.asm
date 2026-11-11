        MODULE bc_ers_math_u32_to_decimal

SECTION code_clib
PUBLIC _bc_ers_math_u32_to_decimal
EXTERN _bc_ers_profile

; Writes the decimal text representation of an unsigned 32-bit value to the
; caller's buffer.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE; if (!value || !output) return INVALID_ARGUMENT;
; ERS(0x4c, 0x04, BCDE=*value, HL=output); return OK;
;
; IX frame: value pointer +4, output pointer +6. Assemble BCDE from four
; little-endian bytes; the temporary AF/BC pushes are not outgoing arguments.
; Output has 11 writable bytes, even for a short decimal representation.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_math_u32_to_decimal:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_math_u32_to_decimal_unavailable
        ld e,(ix+4)
        ld d,(ix+5)
        ld a,d
        or e
        jp z,bc_ers_math_u32_to_decimal_invalid
        ld l,(ix+6)
        ld h,(ix+7)
        ld a,h
        or l
        jp z,bc_ers_math_u32_to_decimal_invalid
        ld a,(de)
        ld c,a
        inc de
        ld a,(de)
        ld b,a
        inc de
        ld a,(de)
        push af
        inc de
        ld a,(de)
        ld d,a
        pop af
        ld e,a                     ; DE = high word
        push bc                    ; save low word
        ld b,d
        ld c,e                     ; BC = high word
        pop de                     ; DE = low word
        rst 08h
        defb 4ch,04h
        pop ix
        ld hl,0
        ret
bc_ers_math_u32_to_decimal_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_math_u32_to_decimal_unavailable:
        pop ix
        ld hl,3
        ret
