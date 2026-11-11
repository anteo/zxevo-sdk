        MODULE zx_read_pixel_index
SECTION code_graphics
PUBLIC _zx_read_pixel_index
EXTERN ts_draw_config
IFDEF TSCONF_VIDEO_BITMAP
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_page
EXTERN ts_packed_begin_window
EXTERN ts_packed_end
ENDIF
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_draw_base
EXTERN zx__pixel_address
EXTERN zx__attribute_address
ENDIF
IFDEF TSCONF_VIDEO_16C
EXTERN ts_packed_address16
ENDIF
IFDEF TSCONF_VIDEO_256C
EXTERN ts_packed_address256
ENDIF
ENDIF

; Read the color index from the selected bitmap or packed surface.
;
; if (!index) return INVALID_ARGUMENT;
; if (mode == UNSELECTED) return NOT_INITIALIZED;
; if (mode == TEXT) return UNSUPPORTED;
; if (!in_bounds(mode, x, y)) return INVALID_ARGUMENT;
; if (mode == ZX) {
;     bit = bitmap(x,y); attr = attribute(x,y);
;     color = ((attr >> (bit ? 0 : 3)) & 7) | ((attr & 0x40) >> 3);
; } else {
;     if (!begin_window()) return BUSY;
;     color = read_packed(mode, x, y); end_window();
; }
; *index = color; return OK;
;
; SDCC x/y/index at SP+2/+4/+6, status in L. IX points at saved IX,
; so the arguments are at +4/+6/+8. ZX requires a mapped screen. Packed
; modes own W3, preserve the index across page restore, and then write
; the output. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_read_pixel_index:
        ld hl,6
        add hl,sp
        ld a,(hl)
        inc hl
        or (hl)
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret z
        ld a,(ts_draw_config)
        cp 0ffh
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
IFDEF TSCONF_VIDEO_BITMAP
        and 3
        cp 3
        ld l,5                       ; ZX_UNSUPPORTED
        ret z
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
IFDEF TSCONF_VIDEO_PACKED
IFDEF TSCONF_VIDEO_ZX
        ld a,(ts_draw_config)
        and 3
        jr z,@zx
ENDIF
        ld a,h
        cp 2
        jr nc,@invalid
        ld a,d
        cp 2
        jr nc,@invalid
        ld a,(ts_draw_page)
        ld d,a
        call ts_packed_begin_window
        jp c,@busy
        ld d,(ix+7)                  ; restore Y after passing the base page
IFDEF TSCONF_VIDEO_16C
IFDEF TSCONF_VIDEO_256C
        ld a,(ts_draw_config)
        and 3
        cp 2
        jr z,@indexed
ENDIF
        ld a,l
        push af
        call ts_packed_address16
        pop af
        rra                          ; odd X selects the low nibble
        ld a,(hl)
        jr c,@nibble
        rrca
        rrca
        rrca
        rrca
@nibble:
        and 0fh
IFDEF TSCONF_VIDEO_256C
        jr @restore
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_256C
@indexed:
        call ts_packed_address256
        ld a,(hl)
ENDIF
@restore:
        push af
        call ts_packed_end
        pop af
IFDEF TSCONF_VIDEO_ZX
        jr @store
ENDIF
ENDIF

IFDEF TSCONF_VIDEO_ZX
@zx:
        ld a,h
        or d
        jr nz,@invalid
        ld a,e
        cp 192
        jr nc,@invalid
        ld a,(ts_draw_base)
        call zx__pixel_address
        and (hl)
        push af                      ; keep the bitmap bit test across the call
        call zx__attribute_address
        pop af
        ld a,(de)
        ld d,a
        jr nz,@ink
        rrca
        rrca
        rrca
@ink:
        and 7
        bit 6,d
        jr z,@store
        or 8
ENDIF
@store:
        ld l,(ix+8)
        ld h,(ix+9)
        ld (hl),a
        ld l,0
        pop ix
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        pop ix
        ret
IFDEF TSCONF_VIDEO_PACKED
@busy:
        ld l,2                       ; ZX_BUSY
        pop ix
        ret
ENDIF
ELSE
        ld l,5                       ; ZX_UNSUPPORTED
        ret
ENDIF
