        MODULE bc__font5_map_page
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
defc BC_FONT5_BITMAP = 1
ELSE
IFDEF BASECONF_VIDEO_TEXT_ATM_640
defc BC_FONT5_BITMAP = 1
ENDIF
ENDIF
IFDEF BC_FONT5_BITMAP
EXTERN bc__video_map_page_regs
SECTION code_clib
PUBLIC bc__font5_map_page

; A = surface page. Return Z for ZX_OK, NZ otherwise.
; Tail adapter to the register selector; preserve B/DE/IX/IY, clobber AF/C/HL.
; Call only while the video lease is held.
bc__font5_map_page:
        ld c,a
        jp bc__video_map_page_regs
ENDIF
