        MODULE bc__video_scroll_horizontal_return
IFNDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
EXTERN _bc__video_scroll_horizontal
ELSE
SECTION code_clib
PUBLIC bc__video_scroll_horizontal_return
bc__video_scroll_horizontal_return:
        ld sp,ix
        pop ix
ENDIF
        ret
IFNDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
PUBLIC bc__video_scroll_horizontal_return
defc bc__video_scroll_horizontal_return = _bc__video_scroll_horizontal
ENDIF
