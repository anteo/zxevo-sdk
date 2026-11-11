        MODULE pen_down
SECTION code_graphics
PUBLIC _pen_down
EXTERN _bc_graphics_pen_down

; Set the cursor pen state. SDCC no arguments. Only AF is volatile.
_pen_down:
        ld a,1
        ld (_bc_graphics_pen_down),a
        ret
