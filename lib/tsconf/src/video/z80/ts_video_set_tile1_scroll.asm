        MODULE ts_video_set_tile1_scroll
EXTERN ts__video_write_scroll
SECTION code_clib
PUBLIC _ts_video_set_tile1_scroll

; Set the tile 1 offsets starting at TS register 44h. SDCC: x at SP+2, y at SP+4.
_ts_video_set_tile1_scroll:
        ld a,45h
        jp ts__video_write_scroll
