        MODULE ts_video_set_border
SECTION code_clib
PUBLIC _ts_video_set_border

; Set the border's CRAM index. Fastcall L = value. Clobbers BC only.
_ts_video_set_border:
        ld bc,0fafh
        out (c),l
        ret
