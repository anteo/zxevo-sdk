        MODULE bc__video_commit_surface
INCLUDE "video/geometry_modes.inc"
SECTION code_clib
PUBLIC _bc__video_commit_surface
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_surface_selected
EXTERN _bc__video_invalidate_cache
EXTERN _bc__console_set_geometry
IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
EXTERN bc__console_update_text_backend
ENDIF
ENDIF

; Publish a draw surface, update console dimensions and invalidate the cache.
; Model:
;
; draw_surface = *surface;
; surface_selected = 1;
; invalidate_cache();
; update_text_backend_availability();
; if (draw_surface.mode < BC_VIDEO_ATM_320) set_geometry(32, 24);
; else set_geometry(draw_surface.mode == BC_VIDEO_ATM_320 ? 40 : 80, 25);
;
; SDCC fastcall HL = validated surface, with no active video operation.
; Preserve IX/IY, clobber AF/BC/DE/HL. No local frame.
; The geometry call takes one word of packed arguments (columns, rows).
_bc__video_commit_surface:
        ld de,_bc_video_draw_surface_state
        ld bc,3                      ; mode, page0, page1
        ldir
        ld a,1
        ld (_bc_video_surface_selected),a
        call _bc__video_invalidate_cache
IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
        call bc__console_update_text_backend
ENDIF
ENDIF

        ld hl,24*256+32
IFDEF BC_GEOMETRY_BY_MODE
        ld a,(_bc_video_draw_surface_state)
        cp 3                         ; BC_VIDEO_ATM_320
        jr c,@set_geometry           ; ZX, Multicolor and Pentagon
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        ld hl,25*256+40
        jr z,@set_geometry
        ld l,80
ELSE
        ld hl,25*256+80
ENDIF
@set_geometry:
ENDIF
        push hl
        call _bc__console_set_geometry
        pop hl
        ret
