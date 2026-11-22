        MODULE ts_video_set_tile0_page
SECTION code_clib
PUBLIC _ts_video_set_tile0_page

; Select T0's atlas page, aligned to 8 pages. Fastcall L = page. Clobbers BC only.
_ts_video_set_tile0_page:
        ld bc,17afh
        out (c),l
        ret
