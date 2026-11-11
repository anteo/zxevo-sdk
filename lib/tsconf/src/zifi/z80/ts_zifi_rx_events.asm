        MODULE ts_zifi_rx_events
SECTION code_clib
PUBLIC _ts_zifi_set_rx_events

; Write the channel's threshold and timeout in adjacent AVR registers.
;
; if (channel > 1) return ZX_INVALID_ARGUMENT;
; port = channel == WIFI ? 0xc5ef : 0xc8ef;
; OUT(port, threshold);
; OUT(port + 0x100, timeout_ms);
; return ZX_OK;
;
; Caller-clean channel at SP+2, threshold at SP+3, timeout at SP+4.
; L = status. Clobber AF/BC/HL, preserve DE/IX/IY.
_ts_zifi_set_rx_events:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 2
        jr nc,@invalid
        ld bc,0c5efh
        or a
        jr z,@write
        ld b,0c8h
@write:
        inc hl
        ld a,(hl)
        out (c),a
        inc b
        inc hl
        ld a,(hl)
        out (c),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
