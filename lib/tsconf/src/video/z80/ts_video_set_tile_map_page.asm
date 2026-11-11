        MODULE ts_video_set_tile_map_page
SECTION code_clib
PUBLIC _ts_video_set_tile_map_page

; Select the tile-map page. Fastcall L = page. Clobbers BC only.
_ts_video_set_tile_map_page:
        ld bc,16afh
        out (c),l
        ret
