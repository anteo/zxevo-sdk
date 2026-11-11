        MODULE undrawto
INCLUDE "abi.inc"
SECTION code_graphics
PUBLIC _undrawto
EXTERN bc__graphics_draw_to

; Pass the Small-C absolute x,y to the cursor drawing routine.
; Caller cleans its arguments. Preserve IX/IY.
_undrawto:
        BC_ABI_LOAD_SMALLC_PAIR
        ld a,1
        jp bc__graphics_draw_to
