        MODULE bc__font5_draw
INCLUDE "font/z80/zx_font.inc"
EXTERN bc__font5_draw_return
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
EXTERN _bc_video_draw_surface_state
EXTERN bc__font5_draw_zx
EXTERN zx__font_rows_from_frame
IFDEF BASECONF_VIDEO_TEXT_ATM_320
EXTERN bc__font5_draw_atm320
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_640
EXTERN bc__font5_draw_atm640
ENDIF
IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
EXTERN bc__font5_draw_pentagon
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
EXTERN bc__font5_draw_multicolor
ENDIF
ENDIF
SECTION code_clib
PUBLIC _bc__font5_draw

; SDCC callback frame after saving IX: x +4, y +6, font +8,
; code +10, ink +11, paper +12, background +13. Preserve IX/IY.
; Prepare five shared bytes: glyph -2, width -3, height -4, background -5.
; Each selected backend extends this context and tail-enters the common return.
;
; Finds the glyph for a character and dispatches it to the renderer for the
; current graphics mode.
;
; Model:
;
; glyph=font->glyphs+8*(valid_code(code)?code-32:'?'-32);
; if (!font->width || !font->height) return;
; dispatch_enabled_backend(mode,glyph,font->width,font->height,background);
;
; Caller holds the lease, supplies a valid descriptor with dimensions 1..8,
; and guarantees the whole glyph is in bounds. AF/BC/DE/HL volatile; IX/IY
; restored through the shared return. The five-byte persistent context above
; may be extended by a backend; it is not an outgoing argument block.
_bc__font5_draw:
IFNDEF BASECONF_VIDEO_TEXT_GRAPHICS
        jp bc__font5_draw_return
ELSE
        push ix
        ld ix,0
        add ix,sp
        push hl
        push hl
        dec sp
        call zx__font_rows_from_frame
        ld (ix-2),l
        ld (ix-1),h
        ld l,(ix+8)
        ld h,(ix+9)
        inc hl
        inc hl
        ld a,(hl)
        ld (ix-3),a
        or a
        jp z,bc__font5_draw_return
        inc hl
        ld a,(hl)
        ld (ix-4),a
        or a
        jp z,bc__font5_draw_return
        ld a,(ix+ZX_TEXT_BACKGROUND_ARG)
        ld (ix-5),a

        ld a,(_bc_video_draw_surface_state)
IFNDEF BASECONF_VIDEO_TEXT_ZX_256
IFNDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
IFNDEF BASECONF_VIDEO_TEXT_PENTAGON_256
IFNDEF BASECONF_VIDEO_TEXT_ATM_320
IFNDEF BASECONF_VIDEO_TEXT_ATM_640
        jp bc__font5_draw_return
ENDIF
ENDIF
ENDIF
ENDIF
ELSE
        or a
        jp z,bc__font5_draw_zx
IFNDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
IFNDEF BASECONF_VIDEO_TEXT_PENTAGON_256
IFNDEF BASECONF_VIDEO_TEXT_ATM_320
IFNDEF BASECONF_VIDEO_TEXT_ATM_640
        jp bc__font5_draw_return
ENDIF
ENDIF
ENDIF
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
        cp 1
        jr nz,@other_modes
        bit 0,(ix-5)
        jp nz,bc__font5_draw_zx     ; same bitmap, keep the raster attributes
        jp bc__font5_draw_multicolor
@other_modes:
IFNDEF BASECONF_VIDEO_TEXT_PENTAGON_256
IFNDEF BASECONF_VIDEO_TEXT_ATM_320
IFNDEF BASECONF_VIDEO_TEXT_ATM_640
        jp bc__font5_draw_return
ENDIF
ENDIF
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
        cp 2
        jp z,bc__font5_draw_pentagon
IFNDEF BASECONF_VIDEO_TEXT_ATM_320
IFNDEF BASECONF_VIDEO_TEXT_ATM_640
        jp bc__font5_draw_return
ENDIF
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_320
        cp 3
        jp z,bc__font5_draw_atm320
IFNDEF BASECONF_VIDEO_TEXT_ATM_640
        jp bc__font5_draw_return
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_640
        cp 4
        jp z,bc__font5_draw_atm640
        jp bc__font5_draw_return
ENDIF
ENDIF
