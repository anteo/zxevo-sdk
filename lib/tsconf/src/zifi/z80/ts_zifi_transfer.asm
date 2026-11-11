        MODULE ts_zifi_transfer
SECTION code_clib
PUBLIC _ts_zifi_read
PUBLIC _ts_zifi_write

; Transfer a nonblocking prefix using the selected channel's FIFO.
;
; if (channel > 1 || !buffer || !limit) return 0;
; status_port = (0xc0 + 2 * channel + write) << 8 | 0xef;
; count = min(IN(status_port), limit);
; for (i = 0; i < count; ++i) {
;     if (write) OUT(0xbfef, buffer[i]); else buffer[i] = IN(0xbfef);
; }
; return count;
;
; Caller-clean channel at SP+2, buffer at SP+3, limit at SP+5. L = count.
; A initially selects direction. D saves the result and E counts down.
; The status read selects the channel for the BFh data alias. Caller
; serializes that selection with IRQ and other FIFO users.
; Clobber AF/BC/DE/HL, preserve IX/IY.
_ts_zifi_read:
        xor a
        jr ts__zifi_transfer
_ts_zifi_write:
        ld a,1
ts__zifi_transfer:
        ld c,a
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 2
        jr nc,@empty
        add a,a
        or c
        add a,0c0h
        ld b,a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        jr z,@empty
        inc hl
        ld a,(hl)
        or a
        jr z,@empty
        ex de,hl
        ld d,a
        ld c,0efh
        in a,(c)
        cp d
        jr c,@count
        ld a,d
@count:
        or a
        jr z,@empty
        ld d,a
        ld e,a
        bit 0,b
        ld b,0bfh
        jr nz,@write
@read:
        in a,(c)
        ld (hl),a
        inc hl
        dec e
        jr nz,@read
        ld l,d
        ret
@write:
        ld a,(hl)
        out (c),a
        inc hl
        dec e
        jr nz,@write
        ld l,d
        ret
@empty:
        ld l,0
        ret
