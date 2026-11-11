        MODULE bc_ers_math_multiply_u16

SECTION code_clib
PUBLIC _bc_ers_math_multiply_u16
EXTERN _bc_ers_profile

; Multiplies two unsigned 16-bit values and stores the full 32-bit product.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE; if (!product) return INVALID_ARGUMENT;
; ERS(0x4c, 0x01, BC=left, DE=right); *product = BCDE; return OK;
;
; IX frame: left +4, right +6, product pointer +8. Store the full product
; as four little-endian bytes, not a truncated 16-bit multiply.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_math_multiply_u16:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_math_multiply_u16_unavailable
        ld l,(ix+8)
        ld h,(ix+9)
        ld a,h
        or l
        jp z,bc_ers_math_multiply_u16_invalid
        ld c,(ix+4)
        ld b,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        rst 08h
        defb 4ch,01h
        ld l,(ix+8)
        ld h,(ix+9)
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),c
        inc hl
        ld (hl),b
        pop ix
        ld hl,0
        ret
bc_ers_math_multiply_u16_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_math_multiply_u16_unavailable:
        pop ix
        ld hl,3
        ret
