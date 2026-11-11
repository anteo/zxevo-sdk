        MODULE ts_console_set_geometry
SECTION code_clib
PUBLIC ts_console_set_geometry
EXTERN ts_draw_config
EXTERN zx__console_in_bounds
IFDEF TSCONF_VIDEO_RASTER
EXTERN ts__video_raster_cells
ENDIF
IFDEF TSCONF_VIDEO_BITMAP
EXTERN zx__font_cell_columns
ENDIF

; Update the selected surface's console grid and home an out-of-bounds cursor.
;
; if (draw_config == UNSELECTED) return;
; size = console_layout(draw_config);
; if (bitmap) size.columns = min(255, size.columns * 8 / font_advance);
; if (!in_bounds(position, size)) position = 0;
;
; Call after changing the layout or font advance. No mapping or glyph access.
; AF/BC/DE/HL volatile, IX/IY preserved. No result.
ts_console_set_geometry:
        ld a,(ts_draw_config)
        cp 0ffh
        ret z
IFDEF TSCONF_VIDEO_ZX
        ld bc,1820h
IFDEF TSCONF_VIDEO_RASTER
        ld e,a
        and 3
        jr z,@store_size
        ld a,e
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_RASTER
        call ts__video_raster_cells
ENDIF
@store_size:
        ld (ts_console_size),bc
IFDEF TSCONF_VIDEO_BITMAP
IFDEF TSCONF_VIDEO_TEXT
        ld a,(ts_draw_config)
        and 3
        cp 3
        jr z,@check_position
ENDIF
        ld a,(ts_console_font_advance)
        ld e,a
        ld a,c
        call zx__font_cell_columns
        ld (ts_console_size),a
ENDIF
@check_position:
        ld bc,(ts_console_position)
        ld de,(ts_console_size)
        call zx__console_in_bounds
        ret c
        ld hl,0
        ld (ts_console_position),hl
        ret

SECTION bss_clib
PUBLIC ts_console_size
PUBLIC ts_console_position
ts_console_size:     defw 0
ts_console_position: defw 0

IFDEF TSCONF_VIDEO_BITMAP
SECTION data_clib
PUBLIC ts_console_font_advance
ts_console_font_advance: defb 8
ENDIF
