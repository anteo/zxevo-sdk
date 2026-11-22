        MODULE ts__graphics_end_writer
IFDEF TSCONF_VIDEO_BITMAP
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts_packed_end
IFDEF TSCONF_VIDEO_ZX
EXTERN ts_draw_config
ENDIF
ENDIF
SECTION code_graphics
PUBLIC ts__graphics_end_writer

; Finish one successful writer scope. An explicit group can retain W3.
ts__graphics_end_writer:
IFDEF TSCONF_VIDEO_PACKED
IFDEF TSCONF_VIDEO_ZX
        ld a,(ts_draw_config)
        and 3
        ret z
ENDIF
        jp ts_packed_end
ELSE
        ret
ENDIF
ENDIF
