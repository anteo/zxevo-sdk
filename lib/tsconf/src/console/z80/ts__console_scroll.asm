        MODULE ts__console_scroll
SECTION code_clib
PUBLIC ts__console_scroll
EXTERN ts_draw_config
EXTERN zx__fill_bytes
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_console_zx_attribute
EXTERN zx__scroll_zx_plane
EXTERN zx__scroll_linear_plane
ENDIF
IFDEF TSCONF_VIDEO_TEXT
EXTERN ts_console_text_attribute
EXTERN ts_console_size
ENDIF
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_draw_base
ELSE
IFDEF TSCONF_VIDEO_TEXT
EXTERN ts_draw_base
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts__console_scroll_packed
ENDIF

; Scroll one cell row on the selected surface. Keep the cursor unchanged.
; The caller owns the mapped ZX/text page. Packed scrolling claims W3.
; Return status in L. Clobber AF/BC/DE/HL, preserve IX/IY.
ts__console_scroll:
        ld a,(ts_draw_config)
        and 3
IFDEF TSCONF_VIDEO_ZX
        jr z,scroll_zx
ENDIF
IFDEF TSCONF_VIDEO_TEXT
        cp 3
        jr z,scroll_text
ENDIF
IFDEF TSCONF_VIDEO_PACKED
        jp ts__console_scroll_packed
ELSE
        ld l,5                       ; ZX_UNSUPPORTED
        ret
ENDIF

IFDEF TSCONF_VIDEO_ZX
; Scroll bitmap rows in logical order, then move the linear attributes.
;
; scroll_zx_plane(base, 8, 0);
; scroll_linear_plane(base+0x1800, 32, 768, zx_attribute());
;
; Caller owns the mapped ZX page. Preserve IX/IY.
scroll_zx:
        ld a,(ts_draw_base)
        ld h,a
        ld l,0
        ld c,8
        xor a
        call zx__scroll_zx_plane
        ld a,(ts_draw_base)
        add a,18h
        ld h,a
        ld l,0
        call ts_console_zx_attribute
        ld de,32
        ld bc,768
        call zx__scroll_linear_plane
        ld l,0
        ret
ENDIF

IFDEF TSCONF_VIDEO_TEXT
; Scroll the visible cells in both halves of each hardware text row.
;
; for (row=0; row+1 < rows; ++row) {
;     copy(codes[row], codes[row+1], columns);
;     copy(attrs[row], attrs[row+1], columns);
; }
; fill(codes[rows-1], ' ', columns);
; fill(attrs[rows-1], text_attribute(), columns);
;
; The selected page is mapped. B is the remaining row count and C is
; the visible column count. One stack word preserves them across LDIR.
scroll_text:
        ld bc,(ts_console_size)
        ld a,(ts_draw_base)
        ld d,a
        inc a
        ld h,a
        ld e,0
        ld l,0
        dec b
@copy:
        push bc
        ld b,0
        ldir
        pop bc
        ld l,80h
        ld e,80h
        push bc
        ld b,0
        ldir
        pop bc
        inc h
        inc d
        ld l,0
        ld e,0
        djnz @copy
        ex de,hl
        push bc
        ld a,' '
        call zx__fill_bytes
        pop bc
        ld l,80h
        call ts_console_text_attribute
        call zx__fill_bytes
        ld l,0
        ret
ENDIF
