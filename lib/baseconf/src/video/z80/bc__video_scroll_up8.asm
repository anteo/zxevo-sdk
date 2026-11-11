        MODULE bc__video_scroll_up8
SECTION code_clib
PUBLIC _bc__video_scroll_up8
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
EXTERN _bc__video_begin
EXTERN _bc__video_end
EXTERN _bc_video_draw_surface_state
IFDEF BASECONF_VIDEO_TEXT_ZX_256
EXTERN bc__video_scroll_up_zx_text
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
EXTERN bc__video_scroll_up_multicolor
ENDIF
IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
EXTERN bc__video_scroll_up_pentagon
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_320
EXTERN bc__video_scroll_up_atm320
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_640
EXTERN bc__video_scroll_up_atm640
ENDIF
ENDIF

; Scrolls a graphics console up one eight-pixel character row and returns the
; video operation status.
;
; C model:
;
;   if (!graphics_text_backends_compiled) return ZX_UNSUPPORTED;
;   status = begin(); if (status != ZX_OK) return status;
;   if (!text_mode_backend_selected) { end(); return ZX_UNSUPPORTED; }
;   scroll_selected_format(8); return end();
;
; SDCC no arguments, status in L. Preserve IX/IY; clobber AF/BC/DE/HL.
; Each mode uses the same native plane kernels as scroll_up_pixels, with one
; extra ZX256 text adapter for its 32-byte attribute row. TEXT and PRIMITIVE
; dispatch remain independent, so neither API links the other's dispatcher.
_bc__video_scroll_up8:
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
        call _bc__video_begin
        ld a,l
        or a
        ret nz
        ld c,8
        ld a,(_bc_video_draw_surface_state)
IFDEF BASECONF_VIDEO_TEXT_ZX_256
        or a
        ld hl,bc__video_scroll_up_zx_text
        jr z,@run
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
        cp 1
        ld hl,bc__video_scroll_up_multicolor
        jr z,@run
ENDIF
IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
        cp 2
        ld hl,bc__video_scroll_up_pentagon
        jr z,@run
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_320
        cp 3
        ld hl,bc__video_scroll_up_atm320
        jr z,@run
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_640
        cp 4
        ld hl,bc__video_scroll_up_atm640
        jr z,@run
ENDIF
        call _bc__video_end
        ld l,5                       ; ZX_UNSUPPORTED, including hardware text
        ret
@run:
        ld de,_bc__video_end
        push de                      ; continuation: backend RET tail-enters end()
        jp (hl)                      ; end() then returns to the original caller
ELSE
        ld l,5
        ret
ENDIF
