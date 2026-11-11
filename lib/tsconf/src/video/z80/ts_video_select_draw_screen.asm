        MODULE ts_video_select_draw_screen
SECTION code_clib
PUBLIC _ts_video_select_draw_screen
EXTERN ts_select_surface
EXTERN ts_video_config

; Select a page in the last configured hardware layout. SDCC page at SP+2,
; base at SP+3. Return L=status. Preserve IX/IY. VConfig must be known.
_ts_video_select_draw_screen:
        ld a,(ts_video_config)
        cp 0ffh
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        ld hl,2
        add hl,sp
        jp ts_select_surface
