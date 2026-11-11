        MODULE ts_video_set_tsu_config
SECTION code_clib
PUBLIC _ts_video_set_tsu_config

; Set the tile and sprite layer controls. Fastcall L = value. Clobbers BC only.
_ts_video_set_tsu_config:
        ld bc,06afh
        out (c),l
        ret
