        MODULE bc__video_scroll_horizontal_atm320
IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN bc__video_scroll_horizontal_packed_init
SECTION code_clib
PUBLIC bc__video_scroll_horizontal_atm320
bc__video_scroll_horizontal_atm320:
        ld a,160
        jp bc__video_scroll_horizontal_packed_init
ENDIF
ENDIF
