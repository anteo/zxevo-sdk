        MODULE ts_video_set_config
SECTION code_clib
PUBLIC _ts_video_set_config
PUBLIC ts_video_config

; Write VConfig and remember its layout for future screen selection.
; Fastcall L=value. Clobbers AF/BC.
_ts_video_set_config:
        ld a,l
        and 0c3h
        ld (ts_video_config),a
        ld bc,00afh
        out (c),l
        ret

SECTION data_clib
ts_video_config: defb 0ffh           ; unknown until the application sets VConfig
