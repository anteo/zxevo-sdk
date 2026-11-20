        MODULE ts__video_check_mode
SECTION code_clib
PUBLIC _ts__video_check_mode
PUBLIC ts__video_check_mode_regs
EXTERN ts__video_validate_mode
EXTERN ts__graphics_group_depth

; Validate a mode number and ensure the video state can be changed.
;
; if (!valid(mode)) return ZX_INVALID_ARGUMENT;
; if (!enabled(config & 3)) return ZX_UNSUPPORTED;
; return graphics_group ? ZX_BUSY : ZX_OK;
;
; Fastcall HL=mode or internal A=high byte, E=low byte. L=status.
; Clobbers AF and L, preserving E at the internal entry.
_ts__video_check_mode:
        ld a,h
        ld e,l
ts__video_check_mode_regs:
        call ts__video_validate_mode
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nz
IFNDEF TSCONF_VIDEO_ALL
        ld a,e
        and 3
        ld l,5                       ; ZX_UNSUPPORTED
IFNDEF TSCONF_VIDEO_ZX
        ret z
ENDIF
IFNDEF TSCONF_VIDEO_16C
        cp 1
        ret z
ENDIF
IFNDEF TSCONF_VIDEO_256C
        cp 2
        ret z
ENDIF
IFNDEF TSCONF_VIDEO_TEXT
        cp 3
        ret z
ENDIF
ENDIF
        ld a,(ts__graphics_group_depth)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz
        ld l,0                       ; ZX_OK
        ret
