        MODULE bc_newirq_status
SECTION code_clib
PUBLIC _bc_newirq_status
EXTERN _bc_newirq_enabled

; Read the pending request bits and clear the output source field.
;
; if (!status) return ZX_INVALID_ARGUMENT;
; if (!newirq_enabled) return ZX_UNAVAILABLE;
; status->pending = in(0x16bd) & 0x7f;
; status->source = 0;
; return ZX_OK;
;
; SDCC status pointer at SP+2, result in L. Preserve DE/IX/IY,
; clobber AF/BC/HL. Output fields are pending +0 and source +1.
_bc_newirq_status:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        or h
        jr z,@invalid
        ld a,(_bc_newirq_enabled)
        or a
        jr z,@disabled
        ld bc,16BDh
        in a,(c)
        and 7Fh
        ld (hl),a
        inc hl
        ld (hl),0
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@disabled:
        ld l,3                       ; ZX_UNAVAILABLE
        ret
