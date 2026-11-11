        MODULE zx_console_get_font
SECTION code_clib
PUBLIC _zx_console_get_font
EXTERN _bc_console_active_font

; Getter: HL=active_font (possibly NULL). No arguments or lease required.
; Preserve AF/BC/DE/IX/IY; only HL changes.
_zx_console_get_font:
        ld hl,(_bc_console_active_font)
        ret
