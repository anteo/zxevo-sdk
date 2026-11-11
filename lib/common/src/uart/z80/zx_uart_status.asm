        MODULE zx_uart_status
SECTION code_clib
PUBLIC _zx_uart_status

; Read the line status once and unpack its six flags.
;
; if (!status) return ZX_INVALID_ARGUMENT;
; bits = in(0xfdef);
; status->rx_ready = (bits >> 0) & 1;
; status->rx_half_full = (bits >> 7) & 1;
; status->tx_ready = (bits >> 5) & 1;
; status->framing_error = (bits >> 3) & 1;
; status->parity_error = (bits >> 2) & 1;
; status->overrun = (bits >> 1) & 1;
; return ZX_OK;
;
; SDCC status pointer at SP+2, status in L. Each field is one byte in
; the order above. Preserve E/IX/IY, clobber AF/BC/D/HL.
_zx_uart_status:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        or h
        jr z,@invalid
        ld bc,0FDEFh
        in d,(c)
        ld a,d
        and 1
        ld (hl),a                    ; rx_ready
        inc hl
        ld a,d
        rlca
        and 1
        ld (hl),a                    ; rx_half_full
        inc hl
        ld a,d
        rlca
        rlca
        rlca
        and 1
        ld (hl),a                    ; tx_ready
        inc hl
        ld a,d
        rrca
        rrca
        rrca
        and 1
        ld (hl),a                    ; framing_error
        inc hl
        ld a,d
        rrca
        rrca
        and 1
        ld (hl),a                    ; parity_error
        inc hl
        ld a,d
        rrca
        and 1
        ld (hl),a                    ; overrun
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
