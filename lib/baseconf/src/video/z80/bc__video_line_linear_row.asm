        MODULE bc__video_line_linear_row
IFDEF BASECONF_VIDEO_MODE_LINEAR
IFDEF BASECONF_VIDEO_PRIMITIVE_LINEAR
EXTERN bc__video_row_offset_40
SECTION code_clib
PUBLIC bc__video_line_linear_row

; Axis frame IX+6 holds the clipped row (0..199). Enter the same arithmetic.
bc__video_line_linear_row:
        ld a,(ix+6)
        jp bc__video_row_offset_40
ENDIF
ENDIF
