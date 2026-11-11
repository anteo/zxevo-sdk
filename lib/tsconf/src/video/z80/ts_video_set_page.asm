        MODULE ts_video_set_page
SECTION code_clib
PUBLIC _ts_video_set_page

; Set the display base page. Fastcall L = value. Clobbers BC only.
_ts_video_set_page:
        ld bc,01afh
        out (c),l
        ret
