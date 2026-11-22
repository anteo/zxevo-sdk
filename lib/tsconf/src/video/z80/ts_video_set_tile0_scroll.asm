        MODULE ts_video_set_tile0_scroll
EXTERN ts__video_write_scroll
SECTION code_clib
PUBLIC _ts_video_set_tile0_scroll

; Set the tile 0 offsets starting at TS register 40h. SDCC: x at SP+2, y at SP+4.
_ts_video_set_tile0_scroll:
        ld a,41h
        jp ts__video_write_scroll
