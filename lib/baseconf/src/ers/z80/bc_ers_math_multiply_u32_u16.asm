        MODULE bc_ers_math_multiply_u32_u16

SECTION code_clib
PUBLIC _bc_ers_math_multiply_u32_u16
EXTERN _bc_ers_profile

; Multiplies an unsigned 32-bit value by a 16-bit value and stores the
; firmware result in a 64-bit output.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE; if (!left || !product) return INVALID_ARGUMENT;
; ERS(0x4c, 0x03, BCDE=*left, HL=right);
; store_le64(product, BCDE, BCDE_alt); return OK;
;
; IX frame: left pointer +4, right word +6, product pointer +8.
; Both register banks are volatile; main BCDE supplies low 32 result bits,
; alternate BCDE supplies high 32 bits. Product requires eight writable bytes.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_math_multiply_u32_u16:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_math_multiply_u32_u16_unavailable
        ld l,(ix+4)
        ld h,(ix+5)
        ld a,h
        or l
        jp z,bc_ers_math_multiply_u32_u16_invalid
        ld l,(ix+8)
        ld h,(ix+9)
        ld a,h
        or l
        jp z,bc_ers_math_multiply_u32_u16_invalid
        ld l,(ix+4)               ; left operand
        ld h,(ix+5)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld l,(ix+6)               ; right operand
        ld h,(ix+7)
        rst 08h
        defb 4ch,03h
        ld l,(ix+8)               ; product low words
        ld h,(ix+9)
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),c
        inc hl
        ld (hl),b
        exx
        ld l,(ix+8)               ; product high words
        ld h,(ix+9)
        inc hl
        inc hl
        inc hl
        inc hl
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),c
        inc hl
        ld (hl),b
        exx
        pop ix
        ld hl,0
        ret
bc_ers_math_multiply_u32_u16_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_math_multiply_u32_u16_unavailable:
        pop ix
        ld hl,3
        ret
