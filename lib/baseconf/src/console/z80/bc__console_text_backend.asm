IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
        MODULE bc__console_text_backend
INCLUDE "console/font_flags.inc"

IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
SECTION code_clib
PUBLIC bc__console_update_text_backend
EXTERN _bc_video_draw_surface_state

IFDEF BASECONF_VIDEO_TEXT_ZX_256
defc BC_TEXT_ZX = 1
ELSE
defc BC_TEXT_ZX = 0
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
defc BC_TEXT_MULTICOLOR = 2
ELSE
defc BC_TEXT_MULTICOLOR = 0
ENDIF
IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
defc BC_TEXT_PENTAGON = 4
ELSE
defc BC_TEXT_PENTAGON = 0
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_320
defc BC_TEXT_ATM320 = 8
ELSE
defc BC_TEXT_ATM320 = 0
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_640
defc BC_TEXT_ATM640 = 16
ELSE
defc BC_TEXT_ATM640 = 0
ENDIF
defc BC_TEXT_MASK = BC_TEXT_ZX + BC_TEXT_MULTICOLOR + BC_TEXT_PENTAGON + BC_TEXT_ATM320 + BC_TEXT_ATM640

; Refresh the backend availability bit after publishing a draw surface.
;
; available = mode < 5 && ((bitmap_text_mask >> mode) & 1);
; cache = (cache & FONT_REQUIRES_BACKEND) | (available ? 0 : BACKEND_MISSING);
;
; No arguments or result. AF/B volatile, C/DE/HL/IX/IY preserved.
; No references to the font descriptor or renderer.
bc__console_update_text_backend:
        ld a,(_bc_video_draw_surface_state)
        cp 5
        jr nc,@cache_mode
        ld b,a
        inc b                        ; rotate the selected mode's bit into carry
        ld a,BC_TEXT_MASK
@rotate:
        rrca
        djnz @rotate
@cache_mode:
        ld a,(bc__console_font_backend_state)
        res BC_FONT_BACKEND_MISSING_BIT,a
        jr c,@store
        set BC_FONT_BACKEND_MISSING_BIT,a
@store:
        ld (bc__console_font_backend_state),a
        ret
ENDIF

SECTION data_clib
PUBLIC bc__console_font_backend_state
; The initial surface is ZX_256 and the default font uses the built-in renderer.
; With no default font, putc checks for its absence before reading this byte.
bc__console_font_backend_state:
IFDEF BASECONF_VIDEO_TEXT_ZX_256
        defb BC_FONT_TEXT_BACKEND
ELSE
        defb BC_FONT_UNSUPPORTED
ENDIF
ENDIF
