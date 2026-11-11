        MODULE ts__console_write_cell
SECTION code_clib
PUBLIC ts__console_write_cell
IFDEF TSCONF_VIDEO_TEXT
EXTERN ts_console_write_text
ENDIF
IFDEF TSCONF_VIDEO_BITMAP
EXTERN ts_console_write_bitmap
IFDEF TSCONF_VIDEO_TEXT
EXTERN ts_draw_config
ENDIF
ENDIF

; Draw A=code at BC=column/row with E=background on the selected console.
; Caller validates the cell and background and keeps the screen accessible.
; Preserve IX/IY.
ts__console_write_cell:
IFDEF TSCONF_VIDEO_BITMAP
IFDEF TSCONF_VIDEO_TEXT
        ld d,a
        ld a,(ts_draw_config)
        and 3
        cp 3
        ld a,d
        jp z,ts_console_write_text
ENDIF
        jp ts_console_write_bitmap
ELSE
        jp ts_console_write_text
ENDIF
