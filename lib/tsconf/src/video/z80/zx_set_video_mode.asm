        MODULE zx_set_video_mode
SECTION code_clib
PUBLIC _zx_set_video_mode
EXTERN ts__video_check_mode_regs
EXTERN _ts__video_set_config

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
        call ts__video_check_mode_regs
        ld a,l
        or a
        ret nz
        ld l,e
        call _ts__video_set_config
        ld l,0                       ; ZX_OK
        ret
