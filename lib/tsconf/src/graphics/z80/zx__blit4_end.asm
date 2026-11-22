        MODULE zx__blit4_end
IFDEF TSCONF_VIDEO_16C
EXTERN _zx_graphics_end
ENDIF
SECTION code_graphics
PUBLIC zx__blit4_end

; Restore W3 at the outermost group boundary. Status in L, IX/IY preserved.
zx__blit4_end:
IFDEF TSCONF_VIDEO_16C
        jp _zx_graphics_end
ELSE
        ld l,0
        ret
ENDIF
