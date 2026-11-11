        MODULE baseconf_console_geometry

PUBLIC __console_x
PUBLIC __console_y
PUBLIC __console_w
PUBLIC __console_h
PUBLIC __console_font_h
PUBLIC _bc_console_font_advance

SECTION bss_clib
__console_x:
        defb 0
__console_y:
        defb 0

SECTION data_clib
__console_w:
        defb 32
__console_h:
        defb 24
__console_font_h:
        defb 8
; Geometry needs only this metric, never a reference to font data/renderers.
_bc_console_font_advance:
        defb 8
