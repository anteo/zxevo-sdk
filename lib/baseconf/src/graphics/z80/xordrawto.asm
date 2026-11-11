        MODULE xordrawto
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _xordrawto
EXTERN bc__graphics_draw_to

; Pass the Small-C absolute x,y to the cursor drawing routine.
; Caller cleans its arguments. Preserve IX/IY.
_xordrawto:
        BC_ABI_LOAD_SMALLC_PAIR
        ld a,2
        jp bc__graphics_draw_to
