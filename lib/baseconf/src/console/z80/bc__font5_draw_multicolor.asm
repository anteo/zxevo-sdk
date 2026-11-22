        MODULE bc__font5_draw_multicolor
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
EXTERN bc__font5_draw_pixels
SECTION code_clib
PUBLIC bc__font5_draw_multicolor

; Multicolor retains the shared pixel fallback. An alias emits no jump/code.
defc bc__font5_draw_multicolor = bc__font5_draw_pixels
ENDIF
ENDIF
