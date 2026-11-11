IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
        MODULE bc__video_vline_draw
SECTION code_clib
PUBLIC bc__video_vline_draw
EXTERN bc__video_line_return
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_OFFSET
EXTERN bc__video_vline_zx_run
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_LINEAR
EXTERN bc__video_vline_linear_run
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_OFFSET
IFDEF BASECONF_VIDEO_PRIMITIVE_LINEAR
EXTERN _bc_video_draw_surface_state
ENDIF
ENDIF

; HL = first CPU byte, D = AND, E = XOR. IX y0 +6, y1 +8.
; Format dispatch occurs once per line; no format branch in the row loop.
;
; Chooses the scanline traversal for the active layout and paints the clipped
; vertical span.
;
; Model:
;
; count=y1-y0+1; run=(mode<ATM_320)?zx_rows:linear_rows;
; run(address,count,AND,XOR); return_through_axis_epilogue();
;
; Tail backend uses the normalized IX axis frame: x +4, y +6, last +8,
; operation +10. An active prepared lease supplies aligned mapped CPU bases;
; coordinates have already been clipped. AF/BC/DE/HL volatile; return through
; video_line_return restores caller IX; IY is preserved.
; Count fits one byte after clipping (at most 192 or 200). Dispatch once,
; then preserve the chosen operation masks across every row.
bc__video_vline_draw:
        ld a,(ix+8)
        sub (ix+6)
        inc a
        ld b,a
        call @run
        jp bc__video_line_return
@run:
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_OFFSET
IFDEF BASECONF_VIDEO_PRIMITIVE_LINEAR
        ld a,(_bc_video_draw_surface_state)
        cp 3
        jp c,bc__video_vline_zx_run
        jp bc__video_vline_linear_run
ELSE
        jp bc__video_vline_zx_run
ENDIF
ELSE
        jp bc__video_vline_linear_run
ENDIF
ENDIF
