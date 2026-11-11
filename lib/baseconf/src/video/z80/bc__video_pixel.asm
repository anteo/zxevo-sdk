        MODULE bc__video_pixel
SECTION code_clib
PUBLIC bc__video_pixel_regs
PUBLIC bc__video_pixel_bool_return
EXTERN _bc_video_operation_depth
EXTERN _bc_video_draw_surface_state
IFDEF BASECONF_VIDEO_MODE_ZX_BITMAP
EXTERN bc__video_pixel_zx
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
EXTERN bc__video_pixel_pentagon
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
EXTERN bc__video_pixel_atm320
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
EXTERN bc__video_pixel_atm640
ENDIF

; Read the index, write a color or test a pixel in the active draw surface.
;
; if (!lease || op < READ || op > TEST) return 0;
; dispatch_enabled_mode();
;
; HL=x, DE=y, C=operation (READ=3, COLOR=4, TEST=5), B=color.
; Coordinates must be in range. Return the index or test bit in L. COLOR
; has no result. Clobber AF/BC/DE/HL, preserve IX/IY. Backends use the
; prepared CPU bases without changing the selected page.
bc__video_pixel_regs:
        ld a,(_bc_video_operation_depth)
        or a
        jr z,@zero
        ld a,c
        sub 3
        cp 3
        jr nc,@zero
        ld a,(_bc_video_draw_surface_state)
IFDEF BASECONF_VIDEO_MODE_ENABLED_ZX_256
        or a
        jp z,bc__video_pixel_zx
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ZX_MULTICOLOR
        cp 1
        jp z,bc__video_pixel_zx
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
        cp 2
        jp z,bc__video_pixel_pentagon
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        cp 3
        jp z,bc__video_pixel_atm320
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
        cp 4
        jp z,bc__video_pixel_atm640
ENDIF
@zero:
        ld l,0
        ret

; Normalize A to a boolean in L.
bc__video_pixel_bool_return:
        or a
        ld l,0
        ret z
        inc l
        ret
