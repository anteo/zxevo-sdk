        MODULE ts_zifi_reset_fifo
SECTION code_clib
PUBLIC _ts_zifi_reset_fifo

; Reset the requested FIFO directions for one channel.
;
; if (channel > 1 || !directions || directions > 3) return INVALID_ARGUMENT;
; OUT(0xc7ef, (channel << 2) | directions);
; return ZX_OK;
;
; Caller-clean channel at SP+2, directions at SP+3, status in L.
; Clobber AF/BC/HL, preserve DE/IX/IY.
_ts_zifi_reset_fifo:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 2
        jr nc,@invalid
        add a,a
        add a,a
        ld c,a
        inc hl
        ld a,(hl)
        or a
        jr z,@invalid
        cp 4
        jr nc,@invalid
        or c
        ld bc,0c7efh
        out (c),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
