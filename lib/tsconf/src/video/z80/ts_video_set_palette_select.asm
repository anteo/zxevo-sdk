        MODULE ts_video_set_palette_select
SECTION code_clib
PUBLIC _ts_video_set_palette_select

; Set the palette groups and graphics bank. Fastcall L = value. Clobbers BC only.
_ts_video_set_palette_select:
        ld bc,07afh
        out (c),l
        ret
