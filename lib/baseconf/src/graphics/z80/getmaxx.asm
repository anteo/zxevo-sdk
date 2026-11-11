        MODULE getmaxx
SECTION code_graphics
PUBLIC _getmaxx
EXTERN _bc__video_width

; Return the highest screen coordinate in HL. SDCC no arguments.
_getmaxx:
        call _bc__video_width
        dec hl
        ret
