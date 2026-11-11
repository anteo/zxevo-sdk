        MODULE ts_packed_pixels
SECTION code_graphics
IFDEF TSCONF_VIDEO_PACKED
PUBLIC ts_packed_write
EXTERN ts_packed_mode
EXTERN ts_packed_color
IFDEF TSCONF_VIDEO_16C
EXTERN ts_packed_address16
ENDIF
IFDEF TSCONF_VIDEO_256C
EXTERN ts_packed_address256
ENDIF

; Replace or toggle one palette index in the canvas, with bounds checks.
;
; if (!(0 <= x && x < 512 && 0 <= y && y < 512)) return;
; offset = mode == 16c ? 256*y+(x>>1) : 512*y+x;
; map_w3(base_page + (offset >> 14));
; p = 0xc000 + (offset & 0x3fff);
; if (mode == 256c) *p = xor ? *p ^ color : color;
; else {
;     shifted_color = (color & 15) << ((x & 1) ? 0 : 4);
;     *p = xor ? *p ^ shifted_color : (*p & neighbour_mask) | shifted_color;
; }
;
; HL=x, DE=y. Caller prepared the canvas and owns W3. Clobbers AF/BC/DE/HL.
; IX/IY preserved for the common line walker. No stack locals.
ts_packed_write:
        ld a,h
        cp 2
        ret nc
        ld a,d
        cp 2
        ret nc
IFDEF TSCONF_VIDEO_16C
IFDEF TSCONF_VIDEO_256C
        ld a,(ts_packed_mode)
        cp 2
        jr z,@indexed
ENDIF

        ld a,l
        push af                      ; keep X parity while obtaining its byte column
        call ts_packed_address16
        pop de                       ; D = low X byte
        ld a,(ts_packed_color)
        and 0fh
        bit 0,d
        jr nz,@low
        rlca
        rlca
        rlca
        rlca
        ld b,a
        ld a,(hl)
        and 0fh
        jr @store_nibble
@low:
        ld b,a
        ld a,(hl)
        and 0f0h
@store_nibble:
        ld c,a
        ld a,(ts__packed_operation)
        cp 2
        ld a,c
        jr nz,@replace_nibble
        ld a,(hl)
        xor b
        ld (hl),a
        ret
@replace_nibble:
        or b
        ld (hl),a
        ret
ENDIF

IFDEF TSCONF_VIDEO_256C
@indexed:
        call ts_packed_address256
        ld a,(ts__packed_operation)
        cp 2
        ld a,(ts_packed_color)
        jr nz,@store_index
        xor (hl)
@store_index:
        ld (hl),a
        ret
ENDIF

SECTION bss_clib
PUBLIC ts__packed_operation
ts__packed_operation: defb 0
ENDIF
