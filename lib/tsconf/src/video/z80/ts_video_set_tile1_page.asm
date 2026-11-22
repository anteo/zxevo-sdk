        MODULE ts_video_set_tile1_page
SECTION code_clib
PUBLIC _ts_video_set_tile1_page

; Select T1's atlas page, aligned to 8 pages. Fastcall L = page. Clobbers BC only.
_ts_video_set_tile1_page:
        ld bc,18afh
        out (c),l
        ret
