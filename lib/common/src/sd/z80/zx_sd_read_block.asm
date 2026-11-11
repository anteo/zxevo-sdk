        MODULE zx_sd_read_block

SECTION code_clib
PUBLIC _zx_sd_read_block
EXTERN _zx__sd_active_transaction

; SDCC caller-clean ABI: transaction:16 at SP+2, buffer:16 at SP+4.
; Transaction bytes: active +0, control_port_high +1, transfer_pending +2.
; Return ZX_OK=0 or ZX_INVALID_ARGUMENT=1; preserve IX/IY.
;
; Reads one 512-byte block within the active SD transaction and marks a
; transfer as pending.
;
; Model:
;
; if (!transaction || !buffer || !transaction->active || active_sd!=transaction)
;     return INVALID_ARGUMENT;
; read_512_bytes(buffer); transaction->transfer_pending=1; return OK;
;
; Requires a live transaction from sd_begin and stable mapped buffer/transaction
; storage. No automatic end/CS change. AF/BC/DE/HL volatile; IX/IY preserved;
; status in HL. Uses two 256-byte INIR bursts; port-decoding constraints below
; are part of the algorithm, not an arbitrary unroll/performance choice.
_zx_sd_read_block:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        jr z,@invalid
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld a,b
        or c
        jr z,@invalid
        ld a,(de)
        or a
        jr z,@invalid
        ld hl,(_zx__sd_active_transaction)
        or a
        sbc hl,de
        jr nz,@invalid
        ld h,b
        ld l,c
        ; Drain the previous responses while clocking exactly 512 FF bytes.
        ; Reads from xx57 have the same decode in ordinary and shadow mode.
        ld bc,0057h
        inir
        ld b,0
        inir
        ex de,hl                    ; DE retained the transaction throughout INIR
        inc hl
        inc hl
        ld (hl),1
        ld hl,0
        ret
@invalid:
        ld hl,1
        ret
