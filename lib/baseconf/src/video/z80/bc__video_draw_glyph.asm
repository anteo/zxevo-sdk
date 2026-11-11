        MODULE bc__video_draw_glyph

SECTION code_clib
PUBLIC bc__video_draw_glyph_regs
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
EXTERN _bc_video_operation_depth
EXTERN _bc_video_draw_surface_state
IFDEF BASECONF_VIDEO_TEXT_ZX_256
EXTERN bc__video_draw_glyph_zx
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
EXTERN bc__video_draw_glyph_multicolor
ENDIF
IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
EXTERN bc__video_draw_glyph_pentagon
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_320
EXTERN bc__video_draw_glyph_atm320
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_640
EXTERN bc__video_draw_glyph_atm640
ENDIF
ENDIF

; Register ABI: HL = glyph, C = cell column, B = cell row,
; E = ink, D = paper with bit 7 set for transparency. Check pointer and lease.
; Caller checks coordinates; the active lease supplies both mapped CPU bases.
; Kernels leave the selected bc_video_cpu_base/bc_video_mapped_page unchanged.
;
; Dispatches an eight-by-eight glyph from register arguments to the renderer
; for the active graphics mode.
;
; Model:
;
; if (!glyph || !lease) return; dispatch_only_enabled_graphics_text_mode();
;
; Native inputs: HL=glyph[8], C=column, B=row, E=ink, D=paper/overlay.
; Dispatcher checks the pointer/lease/mode; caller supplies an in-bounds
; 8x8 cell and both mapped pages. AF/BC/DE/HL volatile; IX/IY preserved.
; No clipping, page remapping or persistent global scratch.
; Hardware text and uncompiled modes perform no bitmap writes; every selected
; backend uses cached CPU bases rather than changing the selected page cache.
bc__video_draw_glyph_regs:
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
        ld a,h
        or l
        ret z
        ld a,(_bc_video_operation_depth)
        or a
        ret z
        ld a,(_bc_video_draw_surface_state)
IFDEF BASECONF_VIDEO_TEXT_ZX_256
        or a
        jp z,bc__video_draw_glyph_zx
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ZX_MULTICOLOR
        cp 1
        jp z,bc__video_draw_glyph_multicolor
ENDIF
IFDEF BASECONF_VIDEO_TEXT_PENTAGON_256
        cp 2
        jp z,bc__video_draw_glyph_pentagon
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_320
        cp 3
        jp z,bc__video_draw_glyph_atm320
ENDIF
IFDEF BASECONF_VIDEO_TEXT_ATM_640
        cp 4
        jp z,bc__video_draw_glyph_atm640
ENDIF
ENDIF
        ret
