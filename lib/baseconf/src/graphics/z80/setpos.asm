        MODULE setpos
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _setpos
EXTERN _bc_graphics_x
EXTERN _bc_graphics_y

; Set the cursor from Small-C x,y. Preserve AF/IX/IY.
_setpos:
        BC_ABI_LOAD_SMALLC_PAIR
        ld (_bc_graphics_x),hl
        ld (_bc_graphics_y),de
        ret
