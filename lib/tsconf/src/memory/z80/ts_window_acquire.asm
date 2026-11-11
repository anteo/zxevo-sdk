        MODULE ts_window_acquire
SECTION code_clib
PUBLIC _ts_window_acquire
EXTERN _ts__memory_window_owner

; Save the current page and install a temporary RAM mapping in W2 or W3.
;
; if (!lease || window > 3) return ZX_INVALID_ARGUMENT;
; if (window < 2) return ZX_UNSUPPORTED;
; if (window_owner) return ZX_BUSY;
; window_owner = lease;
; lease->window = window; lease->previous_page = in(page_port(window));
; lease->active = 1;
; out(page_port(window), page); return ZX_OK;
;
; SDCC window/page bytes at SP+2/+3, lease pointer at SP+4, status in L.
; Lease fields occupy three consecutive bytes. Caller serializes paging and
; keeps the lease resident. AF/BC/DE/HL volatile, IX/IY preserved.
_ts_window_acquire:
        ld hl,2
        add hl,sp
        ld b,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        jr z,@invalid
        ld a,b
        cp 4
        jr nc,@invalid
        cp 2
        jr c,@unsupported
        ld hl,(_ts__memory_window_owner)
        ld a,h
        or l
        jr nz,@busy
        ex de,hl
        ld (_ts__memory_window_owner),hl
        ld (hl),b                    ; window
        inc hl
        ld e,c                       ; temporary page
        ld a,b
        add a,10h
        ld b,a
        ld c,0afh
        in a,(c)
        ld (hl),a                    ; previous_page
        inc hl
        ld (hl),1                    ; active
        out (c),e
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@busy:
        ld l,2                       ; ZX_BUSY
        ret
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
