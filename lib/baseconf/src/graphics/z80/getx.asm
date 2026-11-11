        MODULE getx
SECTION code_graphics
PUBLIC _getx
EXTERN _bc_graphics_x

; Return the cursor coordinate in HL. SDCC no arguments.
_getx:
        ld hl,(_bc_graphics_x)
        ret
