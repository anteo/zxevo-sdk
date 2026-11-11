        MODULE zx__console_draw_run
SECTION code_clib
PUBLIC _zx__console_draw_run
EXTERN ts__console_write_cell
IFDEF TSCONF_VIDEO_TEXT
EXTERN ts_draw_config
ELSE
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_config
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_page
EXTERN ts_packed_begin_window
EXTERN ts_packed_end
ENDIF

; Draw a validated printable run under one W3 lease in packed modes.
;
; if (native_text && transparent) return UNSUPPORTED;
; if (packed && !claim_w3()) return BUSY;
; while (length--) write_cell(column++, row, *text++, background);
; if (packed) release_w3();
; return OK;
;
; SDCC column/row at SP+2/+3, text at +4, length at +6 (nonzero), background +7.
; Return status in L, preserve IX/IY. IX holds the string pointer. Preserve
; D=remaining, E=background and BC=cell across each writer.
_zx__console_draw_run:
        ld hl,2
        add hl,sp
        ld c,(hl)
        inc hl
        ld b,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        push ix
        push de
        pop ix
        ld d,a
        inc hl
        ld e,(hl)
IFDEF TSCONF_VIDEO_TEXT
        bit 0,e
        jr z,@draw
        ld a,(ts_draw_config)
        and 3
        cp 3
        jr z,@unsupported
@draw:
ENDIF
IFDEF TSCONF_VIDEO_PACKED
        call @packed
        jr nc,@next
        push bc
        push de
        ld a,(ts_draw_page)
        ld d,a
        call ts_packed_begin_window
        pop de
        pop bc
        jr c,@busy
ENDIF
@next:
        ld a,(ix+0)
        push bc
        push de
        call ts__console_write_cell
        pop de
        pop bc
        inc ix
        inc c
        dec d
        jr nz,@next
IFDEF TSCONF_VIDEO_PACKED
        call @packed
        call c,ts_packed_end
ENDIF
        ld l,0                       ; ZX_OK
        pop ix
        ret
IFDEF TSCONF_VIDEO_TEXT
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        pop ix
        ret
ENDIF
IFDEF TSCONF_VIDEO_PACKED
@busy:
        ld l,2                       ; ZX_BUSY
        pop ix
        ret
@packed:
        ld a,(ts_draw_config)
        and 3
        dec a
        cp 2                         ; carry for 16c or 256c
        ret
ENDIF
