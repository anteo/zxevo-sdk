        MODULE ts_graphics_group
SECTION code_graphics
PUBLIC _zx_graphics_begin
PUBLIC _zx_graphics_end
EXTERN ts_draw_config
EXTERN ts__graphics_group_depth
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_page
EXTERN ts_packed_begin_window
EXTERN ts_packed_end
ENDIF

; Hold the selected drawing surface across a group of graphics calls.
;
; if (!surface_selected) return ZX_NOT_INITIALIZED;
; if (native_text) return ZX_UNSUPPORTED;
; if (depth >= 253 || (packed && !begin_window(page))) return ZX_BUSY;
; ++depth; return ZX_OK;
;
; No arguments. Status in L. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_graphics_begin:
        ld a,(ts_draw_config)
        cp 0ffh
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        and 3
        cp 3
        jr z,@unsupported
        ld c,a
        ld a,(ts__graphics_group_depth)
        cp 253                       ; leave room for a nested text run and glyph
        jr nc,@busy
IFDEF TSCONF_VIDEO_PACKED
IFDEF TSCONF_VIDEO_ZX
        ld a,c
        or a
        jr z,@opened
ENDIF
        ld a,(ts_draw_page)
        ld d,a
        call ts_packed_begin_window
        jr c,@busy
ENDIF
@opened:
        ; ZX also uses the depth counter to hold the selected surface.
        ld a,(ts__graphics_group_depth)
        inc a
        ld (ts__graphics_group_depth),a
        ld l,0                       ; ZX_OK
        ret
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
@busy:
        ld l,2                       ; ZX_BUSY
        ret

; Release a drawing group level and restore W3 at the outermost packed end.
;
; if (!depth) return ZX_NOT_INITIALIZED;
; --depth; if (packed) end_window(); return ZX_OK;
;
; Surface selection is blocked while a group is open. Return status in L.
; AF/BC/HL volatile, DE/IX/IY preserved.
_zx_graphics_end:
        ld a,(ts__graphics_group_depth)
        or a
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        dec a
        ld (ts__graphics_group_depth),a
IFDEF TSCONF_VIDEO_PACKED
IFDEF TSCONF_VIDEO_ZX
        ld a,(ts_draw_config)
        and 3
        call nz,ts_packed_end
ELSE
        call ts_packed_end
ENDIF
ENDIF
        ld l,0
        ret
