        MODULE ts_video_set_mode
SECTION code_clib
PUBLIC _ts_video_set_mode
EXTERN _ts_video_select_draw_surface
EXTERN _ts_video_set_page
EXTERN _ts_video_set_config

; Select and display the same surface after validating its location.
; SDCC config:8, page:8, base:16 at SP+2 match the descriptor layout.
; L=status. Preserve IX/IY. Caller keeps the required pages accessible.
_ts_video_set_mode:
        ld hl,2
        add hl,sp
        call _ts_video_select_draw_surface
        ld a,l
        or a
        ret nz
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld l,(hl)
        push af
        call _ts_video_set_page
        pop af
        ld l,a
        call _ts_video_set_config
        ld l,0                       ; ZX_OK
        ret
