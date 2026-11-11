        MODULE bc_ers_math_divide_u32

SECTION code_clib
PUBLIC _bc_ers_math_divide_u32
EXTERN _bc_ers_profile

; Divides two unsigned 32-bit values and stores both the quotient and
; remainder.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; if (!dividend || !divisor || !quotient || !remainder) return INVALID_ARGUMENT;
; ERS(0x4c, 0x02, BCDE=*dividend, BCDE_alt=*divisor);
; *quotient = BCDE; *remainder = BCDE_alt; return OK;
;
; IX frame: dividend pointer +4, divisor +6, quotient +8, remainder +10.
; Both register banks are volatile. Values are loaded/stored low word first;
; EXX selects the divisor input and remainder output. *divisor must be nonzero.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_math_divide_u32:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_math_divide_u32_unavailable
        ld l,(ix+4)
        ld h,(ix+5)
        ld a,h
        or l
        jp z,bc_ers_math_divide_u32_invalid
        ld l,(ix+6)
        ld h,(ix+7)
        ld a,h
        or l
        jp z,bc_ers_math_divide_u32_invalid
        ld l,(ix+8)
        ld h,(ix+9)
        ld a,h
        or l
        jp z,bc_ers_math_divide_u32_invalid
        ld l,(ix+10)
        ld h,(ix+11)
        ld a,h
        or l
        jp z,bc_ers_math_divide_u32_invalid
        exx
        ld l,(ix+6)               ; divisor
        ld h,(ix+7)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        exx
        ld l,(ix+4)               ; dividend
        ld h,(ix+5)
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        rst 08h
        defb 4ch,02h
        ld l,(ix+8)               ; quotient
        ld h,(ix+9)
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),c
        inc hl
        ld (hl),b
        exx
        ld l,(ix+10)              ; remainder
        ld h,(ix+11)
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
bc_ers_math_divide_u32_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_math_divide_u32_unavailable:
        pop ix
        ld hl,3
        ret
