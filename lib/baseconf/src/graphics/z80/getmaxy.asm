        MODULE getmaxy
SECTION code_graphics
PUBLIC _getmaxy
EXTERN _bc__video_height

; Return the highest screen coordinate in HL. SDCC no arguments.
_getmaxy:
        call _bc__video_height
        dec hl
        ret
