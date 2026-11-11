        MODULE ts_video_set_sprite_page
SECTION code_clib
PUBLIC _ts_video_set_sprite_page

; Set the sprite atlas base page. Fastcall L = value. Clobbers BC only.
_ts_video_set_sprite_page:
        ld bc,19afh
        out (c),l
        ret
