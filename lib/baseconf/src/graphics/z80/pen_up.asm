        MODULE pen_up
SECTION code_graphics
PUBLIC _pen_up
EXTERN _bc_graphics_pen_down

; Set the cursor pen state. SDCC no arguments. Only AF is volatile.
_pen_up:
        xor a
        ld (_bc_graphics_pen_down),a
        ret
