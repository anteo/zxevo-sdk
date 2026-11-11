        MODULE bc__video_primitive_mode_enabled
SECTION code_clib
PUBLIC bc__video_primitive_mode_enabled_regs

; Each bit corresponds to the bc_video_mode_t value in baseconf.h.
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_256
defc BC_PRIMITIVE_ZX = 1
ELSE
defc BC_PRIMITIVE_ZX = 0
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ZX_MULTICOLOR
defc BC_PRIMITIVE_MULTICOLOR = 2
ELSE
defc BC_PRIMITIVE_MULTICOLOR = 0
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
defc BC_PRIMITIVE_PENTAGON = 4
ELSE
defc BC_PRIMITIVE_PENTAGON = 0
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
defc BC_PRIMITIVE_ATM320 = 8
ELSE
defc BC_PRIMITIVE_ATM320 = 0
ENDIF
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
defc BC_PRIMITIVE_ATM640 = 16
ELSE
defc BC_PRIMITIVE_ATM640 = 0
ENDIF
defc BC_PRIMITIVE_MASK_0 = BC_PRIMITIVE_ZX + BC_PRIMITIVE_MULTICOLOR + BC_PRIMITIVE_PENTAGON
defc BC_PRIMITIVE_MASK_3 = BC_PRIMITIVE_ATM320 + BC_PRIMITIVE_ATM640
defc BC_PRIMITIVE_MASK = BC_PRIMITIVE_MASK_0 + BC_PRIMITIVE_MASK_3

; Return whether graphics primitives are enabled for the supplied video mode.
; Model:
;
; return mode < 5 && ((enabled_mask >> mode) & 1);
;
; A = mode, boolean result in L. Preserve C/DE/H/IX/IY, clobber AF/B/L.
; Full masks need only the range comparison.
bc__video_primitive_mode_enabled_regs:
        ld l,0
IF BC_PRIMITIVE_MASK
        cp 5
IF BC_PRIMITIVE_MASK - 31
        ret nc
        ld b,a
        inc b                        ; rotate the selected bit into carry
        ld a,BC_PRIMITIVE_MASK
@rotate:
        rrca
        djnz @rotate
ENDIF
        rl l
ENDIF
        ret
