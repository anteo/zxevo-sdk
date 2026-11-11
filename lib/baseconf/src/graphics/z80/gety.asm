        MODULE gety
SECTION code_graphics
PUBLIC _gety
EXTERN _bc_graphics_y

; Return the cursor coordinate in HL. SDCC no arguments.
_gety:
        ld hl,(_bc_graphics_y)
        ret
