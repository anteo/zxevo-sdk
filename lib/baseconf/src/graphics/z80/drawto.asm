        MODULE drawto
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _drawto
EXTERN bc__graphics_draw_to

; Pass the Small-C absolute x,y to the cursor drawing routine.
; Caller cleans its arguments. Preserve IX/IY.
_drawto:
        BC_ABI_LOAD_SMALLC_PAIR
        xor a
        jp bc__graphics_draw_to
