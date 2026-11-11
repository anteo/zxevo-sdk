        MODULE bc__video_mode_enabled
SECTION code_clib
PUBLIC _bc__video_mode_enabled
PUBLIC bc__video_mode_enabled_regs

; Each bit corresponds to the bc_video_mode_t value in baseconf.h.
IFDEF BASECONF_VIDEO_MODE_ENABLED_ZX_256
defc BC_MODE_ZX = 1
ELSE
defc BC_MODE_ZX = 0
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ZX_MULTICOLOR
defc BC_MODE_MULTICOLOR = 2
ELSE
defc BC_MODE_MULTICOLOR = 0
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_PENTAGON_256
defc BC_MODE_PENTAGON = 4
ELSE
defc BC_MODE_PENTAGON = 0
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
defc BC_MODE_ATM320 = 8
ELSE
defc BC_MODE_ATM320 = 0
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
defc BC_MODE_ATM640 = 16
ELSE
defc BC_MODE_ATM640 = 0
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_TEXT_80
defc BC_MODE_ATM_TEXT = 32
ELSE
defc BC_MODE_ATM_TEXT = 0
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_EVO_TEXT_80
defc BC_MODE_EVO_TEXT = 64
ELSE
defc BC_MODE_EVO_TEXT = 0
ENDIF
defc BC_MODE_MASK_0 = BC_MODE_ZX + BC_MODE_MULTICOLOR + BC_MODE_PENTAGON
defc BC_MODE_MASK_3 = BC_MODE_ATM320 + BC_MODE_ATM640 + BC_MODE_ATM_TEXT
defc BC_MODE_MASK_6 = BC_MODE_EVO_TEXT
defc BC_MODE_MASK = BC_MODE_MASK_0 + BC_MODE_MASK_3 + BC_MODE_MASK_6

; Return whether the library build includes the supplied video mode.
; Model:
;
; return mode < 7 && ((enabled_mask >> mode) & 1);
;
; SDCC mode:8 at SP+2, boolean result in L. Preserve C/DE/IX/IY,
; clobber AF/B/HL. Full masks need only the range comparison.
; The register entry takes A = mode and preserves H as well.
_bc__video_mode_enabled:
IF BC_MODE_MASK
        ld hl,2
        add hl,sp
        ld a,(hl)
ENDIF
bc__video_mode_enabled_regs:
        ld l,0
IF BC_MODE_MASK
        cp 7
IF BC_MODE_MASK - 127
        ret nc
        ld b,a
        inc b                        ; rotate the selected bit into carry
        ld a,BC_MODE_MASK
@rotate:
        rrca
        djnz @rotate
ENDIF
        rl l
ENDIF
        ret
