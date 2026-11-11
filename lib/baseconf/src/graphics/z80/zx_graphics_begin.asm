        MODULE zx_graphics_begin
SECTION code_graphics
PUBLIC _zx_graphics_begin
EXTERN _bc_video_draw_surface_state
EXTERN _bc__video_begin
IFNDEF BASECONF_VIDEO_PRIMITIVE_ALL
EXTERN bc__video_primitive_mode_enabled_regs
ENDIF

; Acquire a video lease only for an enabled primitive mode. Return the video
; status or ZX_UNSUPPORTED in L. SDCC no arguments. Preserve IX/IY.
_zx_graphics_begin:
        ld a,(_bc_video_draw_surface_state)
IFDEF BASECONF_VIDEO_PRIMITIVE_ALL
        cp 5                         ; BC_VIDEO_ATM_640 + 1
        jp c,_bc__video_begin
ELSE
        call bc__video_primitive_mode_enabled_regs
        ld a,l
        or a
        jp nz,_bc__video_begin
ENDIF
        ld l,5                       ; ZX_UNSUPPORTED
        ret
