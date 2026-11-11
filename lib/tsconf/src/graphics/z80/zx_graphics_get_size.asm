        MODULE zx_graphics_get_size
SECTION code_clib
PUBLIC _zx_graphics_get_size
EXTERN ts_draw_config

; Report the coordinate bounds used by pixel drawing on the selected surface.
;
; if (!size) return INVALID_ARGUMENT;
; if (mode == UNSELECTED) return NOT_INITIALIZED;
; if (mode == TEXT) return UNSUPPORTED;
; *size = mode == ZX ? (256,192) : (512,512); return OK;
;
; Fastcall HL=output struct (two 16-bit fields). Status in L.
; AF/BC/DE/HL volatile, IX/IY preserved. No mapping changes.
_zx_graphics_get_size:
        ld a,h
        or l
        jr z,@invalid
        ld a,(ts_draw_config)
        cp 0ffh
        jr z,@unselected
        and 3
        cp 3
        jr z,@unsupported
        ld de,512
        ld bc,512
        or a
        jr nz,@store
        ld de,256
        ld bc,192
@store:
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),c
        inc hl
        ld (hl),b
        ld l,0
        ret
@invalid:
        ld l,1
        ret
@unselected:
        ld l,4
        ret
@unsupported:
        ld l,5
        ret
