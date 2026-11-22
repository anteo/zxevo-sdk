        MODULE bc__video_pixel_atm320
IFDEF BASECONF_VIDEO_MODE_PACKED
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
EXTERN bc__video_pixel_linear_offset
EXTERN bc__video_pixel_packed_address
SECTION code_clib
PUBLIC bc__video_pixel_atm320
bc__video_pixel_atm320:
        push bc
        ld b,3
        call bc__video_pixel_linear_offset
        jp bc__video_pixel_packed_address
ENDIF
ENDIF
