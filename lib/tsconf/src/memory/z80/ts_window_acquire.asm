        MODULE ts_window_acquire
SECTION code_clib
PUBLIC _ts_window_acquire
EXTERN _ts__memory_window_owner
EXTERN _ts__draw_window_leased
EXTERN ts_draw_base
EXTERN ts_draw_config
EXTERN ts__graphics_group_depth

; Save the current page and install a temporary RAM mapping in W2 or W3.
;
; if (!lease || !aligned(window)) return ZX_INVALID_ARGUMENT;
; if (window < 0x8000) return ZX_UNSUPPORTED;
; if (window_owner) return ZX_BUSY;
; overlaps_draw = draw_config != UNSELECTED && draw_base == window;
; if (overlaps_draw && graphics_depth) return ZX_BUSY;
; draw_window_leased = overlaps_draw;
; window_owner = lease;
; lease->window = window; lease->previous_page = in(page_port(window));
; lease->active = 1;
; out(page_port(window), page); return ZX_OK;
;
; SDCC window address at SP+2, page at SP+4, lease pointer at SP+5.
; Lease fields are a word address, previous page and active byte. Caller serializes paging and
; keeps the lease resident. AF/BC/DE/HL volatile, IX/IY preserved.
_ts_window_acquire:
        ld hl,2
        add hl,sp
        ld a,(hl)
        or a
        jr nz,@invalid
        inc hl
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
        and 3fh
        jr nz,@invalid
        bit 7,b
        jr z,@unsupported
        ld hl,(_ts__memory_window_owner)
        ld a,h
        or l
        jr nz,@busy
        ld a,(ts_draw_config)
        cp 0ffh
        jr z,@claim
        ld a,(ts_draw_base)
        cp b
        jr nz,@claim
        ld a,(ts__graphics_group_depth)
        or a
        jr nz,@busy
        inc a
        ld (_ts__draw_window_leased),a
@claim:
        ex de,hl
        ld (_ts__memory_window_owner),hl
        ld (hl),0                    ; window low byte
        inc hl
        ld (hl),b                    ; window high byte
        inc hl
        ld e,c                       ; temporary page
        ld a,b
        rlca
        rlca
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
