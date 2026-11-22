        MODULE zx__blit4_end
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
EXTERN _bc__video_end
ENDIF
SECTION code_graphics
PUBLIC zx__blit4_end

; Balance a successful begin. Status in L; IX/IY preserved.
zx__blit4_end:
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_320
        jp _bc__video_end
ELSE
        ld l,0
        ret
ENDIF
