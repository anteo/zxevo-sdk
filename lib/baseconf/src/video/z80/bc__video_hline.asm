        MODULE bc__video_hline
SECTION code_clib
PUBLIC _bc__video_hline
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
EXTERN _bc_video_operation_depth
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_cached_width
EXTERN _bc_video_cached_height
EXTERN zx__clip_axis
EXTERN bc__video_line_return
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_BITMAP
EXTERN bc__video_hline_zx
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN bc__video_hline_pentagon
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN bc__video_hline_atm320
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
EXTERN bc__video_hline_atm640
ENDIF
ENDIF

; SDCC three signed 16-bit coordinates, operation:8. Requires an active
; prepared video lease.
; The lease supplies validated CPU bases/dimensions. Preserve IX/IY.
;
; Draws a horizontal line after sorting and clipping its endpoints to the
; active surface.
;
; Model:
;
; if (!lease || operation>2 || y<0 || y>=height) return;
; if (clip_sort(x0,x1,width).empty) return;
; normalize_axis_frame(); dispatch_enabled_mode();
;
; Caller-clean three signed words followed by operation byte. Original IX
; arguments are writable callee-owned copies: hline initially x0 +4,x1 +6,y +8;
; vline initially x +4,y0 +6,y1 +8. Both normalize to x +4,y +6,last +8,op +10.
; No lease acquisition, callback cache or per-pixel C call; AF/BC/DE/HL volatile,
; IX/IY restored. Backend locals below IX are private, not outgoing arguments.
_bc__video_hline:
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
        ld a,(_bc_video_operation_depth)
        or a
        ret z
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+10)
        cp 3
        jp nc,bc__video_line_return
        bit 7,(ix+9)                 ; reject a negative fixed y
        jp nz,bc__video_line_return
        ld hl,(_bc_video_cached_height)
        ld e,(ix+8)
        ld d,(ix+9)
        or a
        sbc hl,de
        jp c,bc__video_line_return
        ld a,h
        or l
        jp z,bc__video_line_return
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        ld bc,(_bc_video_cached_width)
        call zx__clip_axis
        jp c,bc__video_line_return
        ld c,(ix+8)
        ld b,(ix+9)
        ld (ix+4),l
        ld (ix+5),h
        ld (ix+6),c
        ld (ix+7),b
        ld (ix+8),e
        ld (ix+9),d

; Normalized private frame: first x +4, first y +6, last axis coordinate +8,
; operation +10. Parameter slots are private copies and may be overwritten.
        ld a,(_bc_video_draw_surface_state)
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
        or a
        jp z,bc__video_hline_zx
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
        cp 1
        jp z,bc__video_hline_zx
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
        cp 2
        jp z,bc__video_hline_pentagon
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
        cp 3
        jp z,bc__video_hline_atm320
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
        cp 4
        jp z,bc__video_hline_atm640
ENDIF
        jp bc__video_line_return
ELSE
        ret
ENDIF
