        MODULE zx_graphics_end
EXTERN ts__graphics_group_depth
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_packed_end
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_draw_config
ENDIF
ENDIF
SECTION code_graphics
PUBLIC _zx_graphics_end

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
