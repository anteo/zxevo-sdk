        MODULE zx_console_set_font
INCLUDE "font/z80/zx_font.inc"
SECTION code_clib
PUBLIC _zx_console_set_font
EXTERN _bc_console_active_font
EXTERN _bc_console_font_advance
EXTERN _bc_video_draw_surface_state
EXTERN _bc__console_geometry
EXTERN __console_x
EXTERN zx__font_validate
IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
INCLUDE "console/font_flags.inc"
EXTERN bc__console_font_backend_state
ENDIF

; Fastcall HL=font. Validate the eight-byte descriptor without a frame.
; zx_font_t: glyphs +0, width +2, height +3, advance +4, flags +5, draw +6.
;
; Validates and installs a bitmap font, updates the console geometry and
; resets the cursor.
;
; Model:
;
; if (!font || !font->glyphs || width<1 || width>8 || height<1 || height>8 ||
;     advance<width || !font->draw) return INVALID_ARGUMENT;
; if (hardware_text_mode) return UNSUPPORTED;
; cache_font_backend_requirement(font);
; active_font=font; font_advance=advance; refresh_geometry(); cursor_x=cursor_y=0; return OK;
;
; Descriptor storage must remain readable for subsequent draws. Return
; status in L, AF/BC/DE/HL volatile, IX/IY preserved. Publish the
; font/metric only after validation succeeds; no video lease is acquired.
_zx_console_set_font:
        call zx__font_validate
        jr z,@invalid
        ld a,(_bc_video_draw_surface_state)
        sub 5
        cp 2
        ld l,5                       ; ZX_UNSUPPORTED
        ret c
IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
        ld hl,ZX_FONT_FLAGS_OFFSET
        add hl,de                    ; validated font in DE, advance in B
        ld a,(hl)
        and BC_FONT_TEXT_BACKEND
        ld c,a
        ld a,(bc__console_font_backend_state)
        and BC_FONT_BACKEND_MISSING
        or c
        ld (bc__console_font_backend_state),a
ENDIF
        ZX_FONT_INSTALL _bc_console_active_font,_bc_console_font_advance,_bc__console_geometry,__console_x
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
