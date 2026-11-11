        MODULE bc__video_scroll_horizontal
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
PUBLIC _bc__video_scroll_horizontal
PUBLIC bc__video_scroll_horizontal_return
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
EXTERN _bc_video_operation_depth
EXTERN _bc_video_draw_surface_state
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_BITMAP
EXTERN bc__video_scroll_horizontal_zx
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__video_scroll_horizontal_pentagon
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN bc__video_scroll_horizontal_atm320
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
EXTERN bc__video_scroll_horizontal_atm640
ENDIF
ENDIF

; Shifts the active graphics surface left or right by one to eight pixels.
;
; C model:
;
;   if (!lease || pixels < 1 || pixels > 8) return;
;   scroll_selected_mode(pixels, right != 0);
;
; The caller holds a prepared video lease: both page bases stay CPU-visible.
; SDCC pixels:8, right:8; preserve IX/IY. Mode backends allocate only their own
; small stack frame; no row buffer, C request objects or map_page calls.
_bc__video_scroll_horizontal:
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
        ld a,(_bc_video_operation_depth)
        or a
        ret z
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+BC_SCROLL_PIXELS)
        dec a
        cp 8
        jr nc,bc__video_scroll_horizontal_return
        ld a,(_bc_video_draw_surface_state)
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
        or a
        jp z,bc__video_scroll_horizontal_zx
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
        cp 1
        jp z,bc__video_scroll_horizontal_zx
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
        cp 2
        jp z,bc__video_scroll_horizontal_pentagon
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        cp 3
        jp z,bc__video_scroll_horizontal_atm320
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        cp 4
        jp z,bc__video_scroll_horizontal_atm640
ENDIF
bc__video_scroll_horizontal_return:
        ld sp,ix
        pop ix
ENDIF
        ret
IFNDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
defc bc__video_scroll_horizontal_return = _bc__video_scroll_horizontal
ENDIF
