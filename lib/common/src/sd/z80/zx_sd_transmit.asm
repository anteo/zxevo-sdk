        MODULE zx_sd_transmit
SECTION code_clib
PUBLIC _zx_sd_transmit
EXTERN _zx__sd_active_transaction

; Send one byte for the active SD transaction and mark a response pending.
;
; if (!tx || !tx->active || tx != active_sd) return ZX_INVALID_ARGUMENT;
; out(0x0057, byte);
; tx->transfer_pending = 1;
; return ZX_OK;
;
; SDCC transaction pointer at SP+2, byte at SP+4, status in L. The active
; and transfer_pending fields are at +0 and +2. Preserve IX/IY.
_zx_sd_transmit:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        ld a,d
        or e
        jr z,@invalid
        ld a,(de)
        or a
        jr z,@invalid
        ld hl,(_zx__sd_active_transaction)
        or a
        sbc hl,de
        jr nz,@invalid
        ld a,c
        ld bc,0057h
        out (c),a
        ex de,hl
        inc hl
        inc hl
        ld (hl),1
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
