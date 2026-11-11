        MODULE zx_uart_modem_status
SECTION code_clib
PUBLIC _zx_uart_modem_status

; Read the modem status once and unpack its five flags. This clears the CTS-change latch.
;
; if (!status) return ZX_INVALID_ARGUMENT;
; bits = in(0xfeef);
; status->cts = (bits >> 4) & 1;
; status->dsr = (bits >> 5) & 1;
; status->dcd = (bits >> 7) & 1;
; status->ri = (bits >> 6) & 1;
; status->cts_changed = (bits >> 0) & 1;
; return ZX_OK;
;
; SDCC status pointer at SP+2, status in L. Each field is one byte in
; the order above. Preserve E/IX/IY, clobber AF/BC/D/HL.
_zx_uart_modem_status:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        or h
        jr z,@invalid
        ld bc,0FEEFh
        in d,(c)
        ld a,d
        rrca
        rrca
        rrca
        rrca
        and 1
        ld (hl),a                    ; cts
        inc hl
        ld a,d
        rlca
        rlca
        rlca
        and 1
        ld (hl),a                    ; dsr
        inc hl
        ld a,d
        rlca
        and 1
        ld (hl),a                    ; dcd
        inc hl
        ld a,d
        rlca
        rlca
        and 1
        ld (hl),a                    ; ri
        inc hl
        ld a,d
        and 1
        ld (hl),a                    ; cts_changed
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
