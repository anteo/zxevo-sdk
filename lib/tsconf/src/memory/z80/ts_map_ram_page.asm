        MODULE ts_map_ram_page
SECTION code_clib
PUBLIC _ts_map_ram_page
EXTERN _ts__memory_window_owner

; Map one physical RAM page into a caller-owned window.
;
; if (window > 3) return ZX_INVALID_ARGUMENT;
; if (window == 0) return ZX_UNSUPPORTED;
; if (window_owner) return ZX_BUSY;
; out(0x10af + (window << 8), page); return ZX_OK;
;
; SDCC window/page bytes at SP+2/+3, status in L. Caller owns paging and
; keeps needed memory resident. AF/BC/DE/HL volatile, IX/IY preserved.
_ts_map_ram_page:
        ld hl,2
        add hl,sp
        ld a,(hl)
        or a
        jr z,@unsupported
        cp 4
        jr nc,@invalid
        add a,10h
        ld b,a
        ld c,0afh
        inc hl
        ld e,(hl)
        ld hl,(_ts__memory_window_owner)
        ld a,h
        or l
        jr nz,@busy
        out (c),e
        ret                          ; L is zero from the null owner pointer
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
@busy:
        ld l,2                       ; ZX_BUSY
        ret
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
