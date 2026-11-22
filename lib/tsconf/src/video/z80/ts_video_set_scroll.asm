        MODULE ts_video_set_scroll
EXTERN ts__video_write_scroll
SECTION code_clib
PUBLIC _ts_video_set_scroll

; Set the graphics offsets starting at TS register 02h. SDCC: x at SP+2, y at SP+4.
_ts_video_set_scroll:
        ld a,03h
        jp ts__video_write_scroll
