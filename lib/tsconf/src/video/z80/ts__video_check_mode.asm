        MODULE ts__video_check_mode
EXTERN ts__video_check_mode_regs
SECTION code_clib
PUBLIC _ts__video_check_mode

; Adapt the fastcall mode in HL to the native validation entry.
_ts__video_check_mode:
        ld a,h
        ld e,l
        jp ts__video_check_mode_regs
