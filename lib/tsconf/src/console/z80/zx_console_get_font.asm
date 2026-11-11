        MODULE zx_console_get_font
SECTION code_clib
PUBLIC _zx_console_get_font
EXTERN ts_console_font

; Return the selected bitmap font in HL. Preserve registers other than HL.
_zx_console_get_font:
        ld hl,(ts_console_font)
        ret
