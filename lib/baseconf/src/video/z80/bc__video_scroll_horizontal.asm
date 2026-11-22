        MODULE bc__video_scroll_horizontal
INCLUDE "video/scroll_horizontal.inc"
EXTERN bc__video_scroll_horizontal_return
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_operation_depth
EXTERN bc__video_scroll_horizontal_zx
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN bc__video_scroll_horizontal_atm320
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
EXTERN bc__video_scroll_horizontal_atm640
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__video_scroll_horizontal_pentagon
ENDIF
ENDIF
SECTION code_clib
PUBLIC _bc__video_scroll_horizontal

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
IFNDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
        jp bc__video_scroll_horizontal_return
ELSE
        ld a,(_bc_video_operation_depth)
        or a
        ret z
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+BC_SCROLL_PIXELS)
        dec a
        cp 8
        jp nc,bc__video_scroll_horizontal_return
        ld a,(_bc_video_draw_surface_state)
IFNDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
IFNDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
IFNDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        jp bc__video_scroll_horizontal_return
ENDIF
ENDIF
ENDIF
ENDIF
ELSE
        or a
        jp z,bc__video_scroll_horizontal_zx
IFNDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
IFNDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        jp bc__video_scroll_horizontal_return
ENDIF
ENDIF
ENDIF
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
        cp 1
        jp z,bc__video_scroll_horizontal_zx
IFNDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        jp bc__video_scroll_horizontal_return
ENDIF
ENDIF
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
        cp 2
        jp z,bc__video_scroll_horizontal_pentagon
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        jp bc__video_scroll_horizontal_return
ENDIF
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        cp 3
        jp z,bc__video_scroll_horizontal_atm320
IFNDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        jp bc__video_scroll_horizontal_return
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        cp 4
        jp z,bc__video_scroll_horizontal_atm640
        jp bc__video_scroll_horizontal_return
ENDIF
ENDIF
