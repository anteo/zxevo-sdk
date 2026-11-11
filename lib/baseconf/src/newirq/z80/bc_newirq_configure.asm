        MODULE bc_newirq_configure
SECTION code_clib
PUBLIC _bc_newirq_configure
EXTERN _bc_newirq_enabled

; Configure newirq and remember the supplied enable byte.
;
; out(0x14bd, (enabled ? 0x80 : 0) | (vector_flags & 6));
; newirq_enabled = enabled;
;
; SDCC enabled at SP+2, vector_flags at SP+3. D0 auto-clear stays off.
; Preserve IX/IY, clobber AF/BC/DE/HL. No change to the CPU INT state.
_bc_newirq_configure:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld a,(hl)
        and 6
        ld d,a
        ld a,e
        or a
        ld a,d
        jr z,@write
        or 80h
@write:
        ld bc,14BDh
        out (c),a
        ld a,e
        ld (_bc_newirq_enabled),a
        ret
