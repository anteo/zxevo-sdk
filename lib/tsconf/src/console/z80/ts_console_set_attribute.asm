        MODULE ts_console_set_attribute
SECTION code_clib
PUBLIC _ts_console_set_attribute
EXTERN ts_draw_config
EXTERN zx__ink
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_console_zx_flash
ENDIF

; Unpack a native attribute into the shared color indices and, in ZX mode,
; the TSConf FLASH bit.
;
; if (!surface_selected) return;
; if (mode == ZX) {
;     bright = (attr >> 3) & 8; flash = attr & 0x80;
;     (ink, paper) = ((attr & 7) | bright, ((attr >> 3) & 7) | bright);
; } else (ink, paper) = (attr & 15, attr >> 4);
;
; Fastcall L=attribute. No mapping or geometry update. AF/B/DE volatile,
; C/HL/IX/IY preserved.
_ts_console_set_attribute:
        ld a,(ts_draw_config)
        cp 0ffh
        ret z
IFDEF TSCONF_VIDEO_ZX
IFDEF TSCONF_VIDEO_RASTER
        and 3
        jr nz,@indexed
ENDIF
        ld a,l
        and 80h
        ld (ts_console_zx_flash),a
        ld a,l
        and 40h
        rrca
        rrca
        rrca
        ld b,a
        ld a,l
        and 7
        or b
        ld e,a
        ld a,l
        rrca
        rrca
        rrca
        and 7
        or b
        ld d,a
IFDEF TSCONF_VIDEO_RASTER
        jr @store
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_RASTER
@indexed:
        ld a,l
        and 0fh
        ld e,a
        ld a,l
        rrca
        rrca
        rrca
        rrca
        and 0fh
        ld d,a
ENDIF
@store:
        ld (zx__ink),de
        ret
