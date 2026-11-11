        MODULE bc__video_height
INCLUDE "video/geometry_modes.inc"
SECTION code_clib
PUBLIC _bc__video_height
EXTERN _bc_video_cache_valid
EXTERN _bc_video_cached_height
IFDEF BC_GEOMETRY_BY_MODE
EXTERN _bc_video_draw_surface_state
ENDIF

; Return the software-selected height in pixels, or in rows for text.
; Model:
;
; if (cache_valid) return cached_height;
; mode = draw_surface.mode;
; if (mode == ATM320 || mode == ATM640) return 200;
; if (hardware_text_mode(mode)) return 25;
; return 192;
;
; SDCC no arguments, uint16_t result in HL. Preserve BC/DE/IX/IY,
; clobber AF/HL. The mode-specific branches use the build profile.
_bc__video_height:
        ld a,(_bc_video_cache_valid)
        or a
        ld hl,(_bc_video_cached_height)
        ret nz
IFDEF BC_GEOMETRY_BY_MODE
        ld a,(_bc_video_draw_surface_state)
ENDIF
IFDEF BASECONF_VIDEO_MODE_LINEAR
        ld hl,200
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        cp 3                         ; BC_VIDEO_ATM_320
        ret z
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
        cp 4                         ; BC_VIDEO_ATM_640
        ret z
ENDIF
ENDIF
IFDEF BC_GEOMETRY_TEXT
        ld hl,25
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_TEXT_80
        cp 5                         ; BC_VIDEO_ATM_TEXT_80
        ret z
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_EVO_TEXT_80
        cp 6                         ; BC_VIDEO_EVO_TEXT_80
        ret z
ENDIF
ENDIF
        ld hl,192
        ret
