        MODULE ts_video_tile_atlas_pages
SECTION code_clib
PUBLIC _ts_video_set_tile0_page
PUBLIC _ts_video_set_tile1_page

; Select T0's atlas page, aligned to 8 pages. Fastcall L = page. Clobbers BC only.
_ts_video_set_tile0_page:
        ld bc,17afh
        out (c),l
        ret

; Select T1's atlas page, aligned to 8 pages. Fastcall L = page. Clobbers BC only.
_ts_video_set_tile1_page:
        ld bc,18afh
        out (c),l
        ret
