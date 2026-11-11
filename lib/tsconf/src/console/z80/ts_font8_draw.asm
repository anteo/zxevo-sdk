        MODULE ts_font8_draw
INCLUDE "font/z80/zx_font.inc"
SECTION code_clib
PUBLIC ts_font8_draw
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_console_draw_packed
ENDIF
IFDEF TSCONF_VIDEO_ZX
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_draw_config
ENDIF
EXTERN ts_draw_base
EXTERN zx__font_rows_from_frame
EXTERN zx__draw_cell
EXTERN zx__cell_bitmap_address
EXTERN zx__font_overlay_rows
ENDIF

; Draw an eight-pixel glyph at an aligned bitmap cell.
;
; if (packed) draw_packed(8); else draw_or_overlay_zx_cell(x/8,y/8,glyph,attr);
;
; SDCC font callback ABI. IX points at saved IX, with x +4, y +6,
; font +8, code +10, attribute/ink +11, paper +12, background +13. Coordinates are
; in bounds and aligned to eight pixels. AF/BC/DE/HL volatile, IY preserved.
ts_font8_draw:
IFDEF TSCONF_VIDEO_BITMAP
        push ix
        ld ix,0
        add ix,sp
IFDEF TSCONF_VIDEO_PACKED
        ld c,8
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
        ld a,(ix+4)
        rrca
        rrca
        rrca
        and 31
        ld c,a
        ld a,(ix+6)
        rrca
        rrca
        rrca
        and 31
        ld b,a
        ld a,(ts_draw_base)
        ld d,a
        bit 0,(ix+ZX_TEXT_BACKGROUND_ARG)
        jr nz,@overlay
        ld a,(ix+11)
        pop ix
        jp zx__draw_cell
@overlay:
        pop ix
        call zx__cell_bitmap_address
        xor a
        ld c,0ffh
        jp zx__font_overlay_rows
ENDIF
ELSE
        ret
ENDIF
