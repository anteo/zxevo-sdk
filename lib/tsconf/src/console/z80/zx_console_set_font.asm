        MODULE zx_console_set_font
INCLUDE "font/z80/zx_font.inc"
SECTION code_clib
PUBLIC _zx_console_set_font
IFDEF TSCONF_VIDEO_BITMAP
EXTERN ts_console_font
EXTERN ts_draw_config
EXTERN ts_console_position
EXTERN ts_console_font_advance
EXTERN ts_console_set_geometry
ENDIF
EXTERN zx__font_validate

; Validate a bitmap font, publish it and reset the cursor.
;
; if (!valid(font)) return INVALID_ARGUMENT;
; if (native_text || !bitmap_build) return UNSUPPORTED;
; font_state = font; update_console_geometry(); position = 0;
; return OK;
;
; Fastcall HL=descriptor, result L. The descriptor and its glyphs remain
; CPU-accessible while selected. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_console_set_font:
        call zx__font_validate
        jr z,@invalid
IFDEF TSCONF_VIDEO_BITMAP
        ld a,(ts_draw_config)
        cp 0ffh
        jr z,@install
        and 3
        cp 3
        jr z,@unsupported
@install:
        ZX_FONT_INSTALL ts_console_font,ts_console_font_advance,ts_console_set_geometry,ts_console_position
        ret
ENDIF
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret

