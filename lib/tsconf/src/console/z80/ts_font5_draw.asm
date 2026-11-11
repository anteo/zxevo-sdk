        MODULE ts_font5_draw
INCLUDE "font/z80/zx_font.inc"
SECTION code_clib
PUBLIC ts_font5_draw
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_console_draw_packed
ENDIF
IFDEF TSCONF_VIDEO_ZX
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_config
ENDIF
EXTERN ts_draw_base
EXTERN zx__font_rows_from_frame
EXTERN zx__bitmap_offset
EXTERN zx__draw_font5_cell
EXTERN zx__font_overlay_rows
ENDIF

; Draw a five-pixel glyph, retaining neighbouring pixel bits.
;
; if (packed) draw_packed(5);
; else draw_zx_font5(glyph, zx__address(x/8,y), x&7, attr);
;
; SDCC font callback ABI. IX points at saved IX, with x +4, y +6,
; font +8, code +10, attribute/ink +11, paper +12, background +13. X is even, Y is a
; multiple of eight, and the glyph fits. AF/BC/DE/HL volatile, IY preserved.
ts_font5_draw:
IFDEF TSCONF_VIDEO_BITMAP
        push ix
        ld ix,0
        add ix,sp
IFDEF TSCONF_VIDEO_PACKED
        ld c,5
IFDEF TSCONF_VIDEO_ZX
        ld a,(ts_draw_config)
        and 3
        jp nz,ts_console_draw_packed
ELSE
        jp ts_console_draw_packed
ENDIF
ENDIF
IFDEF TSCONF_VIDEO_ZX
        call zx__font_rows_from_frame
        push hl
        ld a,(ix+4)
        rrca
        rrca
        rrca
        and 31
        ld e,a
        ld a,(ts_draw_base)
        ld d,a
        ld c,(ix+6)
        call zx__bitmap_offset
        pop de
        ex de,hl
        ld a,(ix+4)
        and 7
        bit 0,(ix+ZX_TEXT_BACKGROUND_ARG)
        jr nz,@overlay
        ld c,(ix+11)
        pop ix
        jp zx__draw_font5_cell
@overlay:
        ld c,0f8h
        pop ix
        jp zx__font_overlay_rows
ENDIF
ELSE
        ret
ENDIF
