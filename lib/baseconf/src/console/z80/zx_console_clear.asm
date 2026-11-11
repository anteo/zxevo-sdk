        MODULE zx_console_clear

SECTION code_clib
PUBLIC _zx_console_clear
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
EXTERN _bc_video_draw_surface_state
EXTERN bc__text_clear
ENDIF
EXTERN _bc__video_clear
EXTERN __console_x
EXTERN __console_y

; SDCC caller-clean ABI, no arguments. Return the clear status; preserve IX/IY.
;
; Clears the active console and resets its cursor after a successful clear.
;
; Model:
;
; if (hardware_text_mode) return text_clear();
; status=video_clear(); if (status==OK) cursor_x=cursor_y=0; return status;
;
; Acquires/releases through the selected clear backend. AF/BC/DE/HL volatile;
; IX/IY preserved. Errors leave the bitmap cursor unchanged.
_zx_console_clear:
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
        ld a,(_bc_video_draw_surface_state)
        sub 5                        ; ATM_TEXT_80=5, EVO_TEXT_80=6
        cp 2
        jp c,bc__text_clear
ENDIF
        call _bc__video_clear
        ld a,l
        or a
        ret nz
        ld (__console_x),a
        ld (__console_y),a
        ret
