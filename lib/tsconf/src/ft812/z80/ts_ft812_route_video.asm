        MODULE ts_ft812_route_video
SECTION code_clib

PUBLIC _ts_ft812_route_video
EXTERN _ts_video_set_config

; Replace VConfig.D2 and tail-call the native setter. The caller supplies
; the full config byte and an enable byte on the stack (SDCC caller-clean).
; Clobbers AF and HL, plus the native setter's clobbers.
_ts_ft812_route_video:
        ld hl,2
        add hl,sp
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        res 2,l
        ld a,h
        or a
        jr z,@ready
        set 2,l
@ready:
        jp _ts_video_set_config
