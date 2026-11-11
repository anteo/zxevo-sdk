        MODULE ts_window_release
SECTION code_clib
PUBLIC _ts_window_release
EXTERN _ts__memory_window_owner

; Restore the original page and invalidate the active window lease.
;
; if (!lease || !lease->active) return ZX_INVALID_ARGUMENT;
; if (window_owner != lease) return ZX_BUSY;
; out(page_port(lease->window), lease->previous_page);
; lease->active = 0; window_owner = NULL; return ZX_OK;
;
; SDCC lease pointer at SP+2, status in L. The original, resident lease is
; unchanged since acquire. AF/BC/DE/HL volatile, IX/IY preserved.
_ts_window_release:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld a,d
        or e
        jr z,@invalid
        ld hl,2
        add hl,de
        ld a,(hl)
        or a
        jr z,@invalid
        push hl                      ; &lease->active, carry clear
        ld hl,(_ts__memory_window_owner)
        sbc hl,de
        pop hl
        jr nz,@busy
        dec hl
        ld e,(hl)                    ; previous_page
        dec hl
        ld a,(hl)                    ; window
        add a,10h
        ld b,a
        ld c,0afh
        out (c),e
        inc hl
        inc hl
        ld (hl),0                    ; active
        ld hl,0
        ld (_ts__memory_window_owner),hl
        ret                          ; ZX_OK in L
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@busy:
        ld l,2                       ; ZX_BUSY
        ret
