        MODULE ts__video_set_config
SECTION code_clib
PUBLIC _ts__video_set_config
PUBLIC ts_video_config

; Write VConfig and remember its mode, raster and layer flags for future screen selection.
; Fastcall L=value. Clobbers AF/BC.
_ts__video_set_config:
        ld a,l
        and 0f3h
        ld (ts_video_config),a
        ld bc,00afh
        out (c),l
        ret

SECTION data_clib
ts_video_config: defb 0ffh           ; unknown until the application sets VConfig
