        MODULE bc_screen_surface
SECTION code_clib
PUBLIC _bc_screen_surface

defc BC_SCREEN_SURFACE_FALLBACK = 75h

; Describe a standard screen without changing hardware or drawing state.
; Unknown and excluded modes return the fallback pages for either screen.
; Model:
;
; pair = mode < 7 ? screen0_pages[mode] : FALLBACK;
; if (pair != FALLBACK && screen) pair += 0x22;
; return (bc_surface_t){mode, pair & 15, pair >> 4};
;
; SDCC hidden result pointer at SP+2, mode:8 at SP+4, screen:8 at SP+5.
; Write {mode, page0, page1} to the caller's buffer. Preserve IX/IY, clobber
; AF/BC/DE/HL. No local stack storage.
_bc_screen_surface:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        ld (de),a
        inc de

        cp 7
        jr nc,@fallback
        ld c,a
        ld b,0
        inc hl
        ld a,(hl)
        or a
        ld hl,bc_screen_surface_pages
        add hl,bc                    ; preserves Z from the screen test
        ld a,(hl)
        jr z,@write_pages
IFNDEF BASECONF_VIDEO_ALL_MODES
        cp BC_SCREEN_SURFACE_FALLBACK
        jr z,@write_pages
ENDIF
        add a,22h                    ; +2 in each nibble (base pages are <= 8)
@write_pages:
        ex de,hl
        ld c,a
        and 0Fh
        ld (hl),a
        inc hl
        ld a,c
        rrca
        rrca
        rrca
        rrca
        and 0Fh
        ld (hl),a
        ret

@fallback:
        ld a,BC_SCREEN_SURFACE_FALLBACK
        jr @write_pages

SECTION rodata_clib
; Indexed by bc_video_mode_t. Low nibble = page0, high nibble = page1.
bc_screen_surface_pages:
IFDEF BASECONF_VIDEO_MODE_ENABLED_ZX_256
        defb 55h
ELSE
        defb BC_SCREEN_SURFACE_FALLBACK
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ZX_MULTICOLOR
        defb 55h
ELSE
        defb BC_SCREEN_SURFACE_FALLBACK
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
        defb 54h
ELSE
        defb BC_SCREEN_SURFACE_FALLBACK
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        defb 51h
ELSE
        defb BC_SCREEN_SURFACE_FALLBACK
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
        defb 51h
ELSE
        defb BC_SCREEN_SURFACE_FALLBACK
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_TEXT_80
        defb 51h
ELSE
        defb BC_SCREEN_SURFACE_FALLBACK
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_EVO_TEXT_80
        defb 88h
ELSE
        defb BC_SCREEN_SURFACE_FALLBACK
ENDIF
