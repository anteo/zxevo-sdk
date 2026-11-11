        MODULE bc__video_scroll_up_pixels
SECTION code_clib
PUBLIC _bc__video_scroll_up_pixels
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
EXTERN _bc_video_operation_depth
EXTERN _bc_video_draw_surface_state
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
EXTERN bc__video_scroll_up_zx
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
EXTERN bc__video_scroll_up_multicolor
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__video_scroll_up_pentagon
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN bc__video_scroll_up_atm320
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
EXTERN bc__video_scroll_up_atm640
ENDIF
ENDIF

; Scrolls the active graphics surface up by a requested number of scanlines
; using its native layout.
;
; C model:
;
;   if (!active_lease || rows == 0) return;
;   dispatch_only_primitive_modes(rows);
;
; SDCC rows:8 at SP+2; native backends receive C = rows. Preserve IX/IY;
; clobber AF/BC/DE/HL. The caller owns begin/end. Unsupported modes are no-ops.
; ZX256 attributes stay unchanged even for rows==8; other formats scroll their
; native planes together. Each plane clamps rows to its own height.
_bc__video_scroll_up_pixels:
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
        ld a,(_bc_video_operation_depth)
        or a
        ret z
        ld hl,2
        add hl,sp
        ld c,(hl)
        ld a,c
        or a
        ret z
        ld a,(_bc_video_draw_surface_state)
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
        or a
        jp z,bc__video_scroll_up_zx
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
        cp 1
        jp z,bc__video_scroll_up_multicolor
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
        cp 2
        jp z,bc__video_scroll_up_pentagon
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        cp 3
        jp z,bc__video_scroll_up_atm320
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        cp 4
        jp z,bc__video_scroll_up_atm640
ENDIF
ENDIF
        ret
