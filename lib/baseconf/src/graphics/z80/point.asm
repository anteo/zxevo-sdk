        MODULE point
SECTION code_graphics
PUBLIC _point
PUBLIC _c_point
EXTERN bc__graphics_read_point

; Small-C caller-clean x,y. Return the clipped point result in L and
; zero-extend it in HL for the int API. Preserve IX/IY.
_c_point:
_point:
        ld a,5
        jp bc__graphics_read_point
