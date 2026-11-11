IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
        MODULE bc__font5_draw_packed

SECTION code_clib
EXTERN bc__font5_draw_pixels

; Tail ABI: IX anchors the font callback frame, SP=IX-5, with glyph/width/
; height/flags initialized. Requires an active lease and in-bounds glyph;
; AF/BC/DE/HL volatile, shared epilogue restores caller IX, IY preserved.
; Pentagon uses the pixel renderer directly.
PUBLIC bc__font5_draw_pentagon
defc bc__font5_draw_pentagon = bc__font5_draw_pixels
ENDIF
