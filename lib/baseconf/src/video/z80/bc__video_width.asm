        MODULE bc__video_width
INCLUDE "video/geometry_modes.inc"
SECTION code_clib
PUBLIC _bc__video_width
EXTERN _bc_video_cache_valid
EXTERN _bc_video_cached_width
IFDEF BC_GEOMETRY_BY_MODE
EXTERN _bc_video_draw_surface_state
ENDIF

; Return the software-selected width in pixels, or in columns for text.
; Model:
;
; if (cache_valid) return cached_width;
; mode = draw_surface.mode;
; if (mode == ATM320) return 320;
; if (mode == ATM640) return 640;
; if (hardware_text_mode(mode)) return 80;
; return 256;
;
; SDCC no arguments, uint16_t result in HL. Preserve BC/DE/IX/IY,
; clobber AF/HL. The mode-specific branches use the build profile.
_bc__video_width:
        ld a,(_bc_video_cache_valid)
        or a
        ld hl,(_bc_video_cached_width)
        ret nz
IFDEF BC_GEOMETRY_BY_MODE
        ld a,(_bc_video_draw_surface_state)
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        cp 3                         ; BC_VIDEO_ATM_320
        ld hl,320
        ret z
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
        cp 4                         ; BC_VIDEO_ATM_640
        ld hl,640
        ret z
ENDIF
IFDEF BC_GEOMETRY_TEXT
        ld hl,80
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_TEXT_80
        cp 5                         ; BC_VIDEO_ATM_TEXT_80
        ret z
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_EVO_TEXT_80
        cp 6                         ; BC_VIDEO_EVO_TEXT_80
        ret z
ENDIF
ENDIF
        ld hl,256
        ret
