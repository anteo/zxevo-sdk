        MODULE ts_console_font_state
SECTION data_clib
PUBLIC ts_console_font

IFDEF TSCONF_VIDEO_BITMAP
EXTERN _zx_font8
ts_console_font: defw _zx_font8
ELSE
ts_console_font: defw 0
ENDIF
