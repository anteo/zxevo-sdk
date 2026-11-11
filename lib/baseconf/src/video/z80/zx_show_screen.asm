        MODULE zx_show_screen
SECTION code_clib
PUBLIC _zx_show_screen
EXTERN _bc_video_operation_depth
EXTERN _bc_get_video_mode
IFNDEF BASECONF_VIDEO_ALL_MODES
EXTERN bc__video_mode_enabled_regs
ENDIF
EXTERN _bc_select_screen

; Select the displayed screen while retaining the prepared draw context.
; Model:
;
; if (screen > ZX_SCREEN_1) return ZX_INVALID_ARGUMENT;
; if (operation_depth) return ZX_BUSY;
; live_mode = get_video_mode();
; if (live_mode == BC_VIDEO_UNKNOWN) return ZX_UNAVAILABLE;
; if (!all_modes && !mode_enabled(live_mode)) return ZX_UNSUPPORTED;
; return select_screen(screen);
;
; SDCC screen:8 at SP+2, status in L. Preserve IX/IY, clobber AF/BC/DE/HL.
; No local frame. select_screen changes only the displayed-screen bit of 7FFD,
; so the active CPU map and the prepared drawing addresses stay valid.
_zx_show_screen:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 2
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret nc
        ld a,(_bc_video_operation_depth)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz

        call _bc_get_video_mode
        ld a,l
        cp 0FFh                      ; BC_VIDEO_UNKNOWN
        ld l,3                       ; ZX_UNAVAILABLE
        ret z
IFNDEF BASECONF_VIDEO_ALL_MODES
        call bc__video_mode_enabled_regs
        ld a,l
        or a
        ld l,5                       ; ZX_UNSUPPORTED
        ret z
ENDIF

        jp _bc_select_screen
