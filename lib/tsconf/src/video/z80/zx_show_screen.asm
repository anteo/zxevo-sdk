        MODULE zx_show_screen
SECTION code_clib
PUBLIC _zx_show_screen
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_video_config
EXTERN ts__graphics_group_depth
EXTERN _ts_video_set_page
ENDIF

; Show a standard ZX screen through VPage, leaving CPU paging and the
; draw surface intact.
;
; if (screen > 1) return ZX_INVALID_ARGUMENT;
; if (!zx_build) return ZX_UNSUPPORTED;
; if (graphics_group) return ZX_BUSY;
; if (!known_display_mode) return ZX_NOT_INITIALIZED;
; if (display_mode != ZX) return ZX_UNSUPPORTED;
; set_display_page(5 + 2*screen); return ZX_OK;
;
; SDCC screen byte at SP+2. Status in L. AF/BC/DE/HL volatile, IX/IY preserved.
_zx_show_screen:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
IFDEF TSCONF_VIDEO_ZX
        ld e,a
        ld a,(ts__graphics_group_depth)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz
        ld a,(ts_video_config)
        cp 0ffh
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        and 3
        jr nz,@unsupported
        ld a,e
        add a,a
        add a,5
        ld l,a
        call _ts_video_set_page
        ld l,0                       ; ZX_OK
        ret
@unsupported:
ENDIF
        ld l,5                       ; ZX_UNSUPPORTED
        ret
