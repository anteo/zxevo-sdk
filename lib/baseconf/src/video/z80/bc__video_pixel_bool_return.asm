        MODULE bc__video_pixel_bool_return
SECTION code_clib
PUBLIC bc__video_pixel_bool_return

; Normalize A to a boolean in L.
bc__video_pixel_bool_return:
        or a
        ld l,0
        ret z
        inc l
        ret
