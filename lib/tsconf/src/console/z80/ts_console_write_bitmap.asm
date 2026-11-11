        MODULE ts_console_write_bitmap
SECTION code_clib
IFDEF TSCONF_VIDEO_BITMAP
PUBLIC ts_console_write_bitmap
EXTERN ts_console_font
EXTERN zx__font_position
EXTERN zx__font_call
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_console_zx_attribute
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_config
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_PACKED
EXTERN zx__ink
ENDIF

; Invoke the bitmap font's renderer at the pixel origin of the requested cell.
;
; colors = mode == ZX ? (zx_attribute(), 0) : (ink, paper);
; font->draw(column*font->advance,row*8,font,code,ink,paper,background);
;
; A=code, B=row, C=column, E=background. The surface must be writable.
; IX anchors the common nine-byte draw context and background at IX-10.
; Preserve IX/IY, clobber AF/BC/DE/HL.
ts_console_write_bitmap:
        push ix
        ld ix,0
        add ix,sp
        ld hl,-10
        add hl,sp
        ld sp,hl
        ld (ix-9),a
        ld (ix-10),e
        ld a,c
        ld c,b
        ld hl,(ts_console_font)
        call zx__font_position
IFDEF TSCONF_VIDEO_ZX
IFDEF TSCONF_VIDEO_PACKED
        ld a,(ts_draw_config)
        and 3
        jr nz,@packed
ENDIF
        call ts_console_zx_attribute
        ld e,a
        ld d,0
IFDEF TSCONF_VIDEO_PACKED
        jr @colors
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_PACKED
@packed:
        ld de,(zx__ink)
ENDIF
@colors:
        ld (ix-8),e
        ld (ix-7),d
        ld a,(ix-10)
        call zx__font_call
        ld sp,ix
        pop ix
        ret
ENDIF
