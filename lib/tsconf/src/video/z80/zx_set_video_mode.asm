        MODULE zx_set_video_mode
SECTION code_clib
PUBLIC _zx_set_video_mode
EXTERN ts__video_validate_mode
EXTERN _ts__video_set_config
EXTERN ts__graphics_group_depth

; Decode the common mode number and write a supported TSConf display layout.
;
; if (mode == ZX_VIDEO_ZX_256) config = 0;
; else if ((mode >> 8) == 1 && valid_nonzero_config(mode & 255))
;     config = mode & 255;
; else return ZX_INVALID_ARGUMENT;
; if (!enabled(config & 3)) return ZX_UNSUPPORTED;
; if (graphics_group) return ZX_BUSY;
; write_config(config); return ZX_OK;
;
; SDCC mode at SP+2. Status in L. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_set_video_mode:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld a,(hl)
        call ts__video_validate_mode
        jr nz,@invalid
IFNDEF TSCONF_VIDEO_ALL
        ld a,e
        and 3
IFNDEF TSCONF_VIDEO_ZX
        jr z,@unsupported
ENDIF
IFNDEF TSCONF_VIDEO_16C
        cp 1
        jr z,@unsupported
ENDIF
IFNDEF TSCONF_VIDEO_256C
        cp 2
        jr z,@unsupported
ENDIF
IFNDEF TSCONF_VIDEO_TEXT
        cp 3
        jr z,@unsupported
ENDIF
ENDIF
        ld a,(ts__graphics_group_depth)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz
        ld l,e
        call _ts__video_set_config
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
IFNDEF TSCONF_VIDEO_ALL
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
ENDIF
