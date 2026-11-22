        MODULE zx__console_draw_run
SECTION code_clib
PUBLIC _zx__console_draw_run
EXTERN _ts__draw_window_leased
IFDEF TSCONF_VIDEO_TEXT
EXTERN ts_draw_base
EXTERN ts_console_text_attribute
EXTERN ts_draw_config
ELSE
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_config
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_BITMAP
EXTERN ts__console_write_cell
ENDIF
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_page
EXTERN ts_packed_begin_window
EXTERN ts_packed_end
ENDIF

; Draw a validated printable run under one W3 lease in packed modes.
;
; if (draw_window_leased) return BUSY;
; if (native_text && transparent) return UNSUPPORTED;
; if (native_text) write codes and one common attribute along the row, then return OK;
; if (packed && !claim_w3()) return BUSY;
; while (length--) write_cell(column++, row, *text++, background);
; if (packed) release_w3();
; return OK;
;
; SDCC column/row at SP+2/+3, text at +4, length at +6 (nonzero), background +7.
; Return status in L, preserve IX/IY. Native text uses DE=source, HL=cell,
; B=count and C=attribute. Bitmap output keeps the string pointer in IX and
; saves D=remaining, E=background and BC=cell across each font callback.
_zx__console_draw_run:
        ld a,(_ts__draw_window_leased)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz
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
IFDEF TSCONF_VIDEO_TEXT
IFDEF TSCONF_VIDEO_BITMAP
        ld a,(ts_draw_config)
        and 3
        cp 3
        jr nz,@bitmap
ENDIF
        ld a,(hl)                    ; clipped nonempty run fits one text row
        inc hl
        bit 0,(hl)
        ld l,5                       ; ZX_UNSUPPORTED
        ret nz
        ld l,c
        ld c,a
        ld a,(ts_draw_base)
        or b
        ld h,a
        ld b,c
        push de                      ; attribute encoder uses E
        call ts_console_text_attribute
        pop de
        ld c,a
@text:
        ld a,(de)
        inc de
        ld (hl),a
        set 7,l                      ; attributes start 128 bytes after codes
        ld (hl),c
        res 7,l
        inc l
        djnz @text
        ld l,0
        ret
ENDIF
IFDEF TSCONF_VIDEO_BITMAP
@bitmap:
        ld a,(hl)
        push ix
        push de
        pop ix
        ld d,a
        inc hl
        ld e,(hl)
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
ENDIF
