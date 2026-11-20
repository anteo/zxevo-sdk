        MODULE zx_get_video_mode
SECTION code_clib
PUBLIC _zx_get_video_mode
EXTERN ts_video_config

; Return the SDK's cached mode in HL. Tag only nonzero, known VConfig values.
_zx_get_video_mode:
        ld a,(ts_video_config)
        ld l,a
        ld h,0
        or a
        ret z                        ; ZX_VIDEO_ZX_256
        cp 0ffh
        ret z                        ; ZX_VIDEO_UNKNOWN
        inc h
        ret
