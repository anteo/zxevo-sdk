        MODULE zx_sd_wait
SECTION code_clib
PUBLIC _zx_sd_wait_data
PUBLIC _zx_sd_wait_ready
EXTERN _zx__sd_active_transaction

; Wait for a read token or for the card to release SPI busy.
;
; if (!current(transaction) || !polls) return ZX_INVALID_ARGUMENT;
; if (!transaction->transfer_pending) { IN(0x0057); transaction->transfer_pending = 1; }
; while (polls--) {
;     byte = IN(0x0057);
;     if (byte == expected) return ZX_OK;
;     if (expected == 0xfe && byte != 0xff) return ZX_IO_ERROR;
; }
; return ZX_TIMEOUT;
;
; SDCC handle at SP+2 and poll count at SP+4, result in L.
; Preserve IX/IY, clobber AF/BC/DE/HL. The next response remains pending.
_zx_sd_wait_data:
        ld a,0FEh
        jr zx__sd_wait_regs
_zx_sd_wait_ready:
        ld a,0FFh
zx__sd_wait_regs:
        ld hl,2
        add hl,sp
        push af
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld a,d
        or e
        jr z,@invalid
        ld hl,(_zx__sd_active_transaction)
        or a
        sbc hl,de
        jr nz,@invalid
        ld a,b
        or c
        jr z,@invalid
        ex de,hl
        inc hl
        inc hl
        ld d,b
        ld e,c
        ld bc,0057h
        bit 0,(hl)
        jr nz,@start
        in a,(c)                     ; discard stale data, clock the first byte
        ld (hl),1
@start:
        pop af
        ld h,a
@poll:
        in a,(c)
        cp h
        jr z,@ok
        cp 0FFh
        jr z,@next
        bit 0,h                      ; FFh (ready) ignores all other bytes
        jr z,@error                  ; FEh (data) rejects a non-idle byte
@next:
        dec de
        ld a,d
        or e
        jr nz,@poll
        ld l,7                       ; ZX_TIMEOUT
        ret
@error:
        ld l,8                       ; ZX_IO_ERROR
        ret
@invalid:
        pop af
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@ok:
        ld l,0                       ; ZX_OK
        ret
