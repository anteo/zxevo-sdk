        MODULE zx__blit4_begin
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
EXTERN _bc__video_begin
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_surface_selected
ENDIF
SECTION code_graphics
PUBLIC zx__blit4_begin

; Acquire the already mapped ATM320 surface without pulling pixel primitives
; or unrelated video modes into the blitter's archive dependencies.
;
; if (!selected) return NOT_INITIALIZED;
; if (mode != ATM320) return UNSUPPORTED;
; status=video_begin(); return status,320,200;
;
; IX=common blitter frame. L=status, BC/DE=bounds on success.
; AF/BC/DE/HL volatile; IX/IY preserved. Source must not alias either page.
zx__blit4_begin:
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        ld a,(_bc_video_surface_selected)
        or a
        ld l,4
        ret z
        ld a,(_bc_video_draw_surface_state)
        cp 3                         ; BC_VIDEO_ATM_320
        jr nz,@unsupported
        call _bc__video_begin
        ld bc,320
        ld de,200
        ret
@unsupported:
ENDIF
        ld l,5
        ret
