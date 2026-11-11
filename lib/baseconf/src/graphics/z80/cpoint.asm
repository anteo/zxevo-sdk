        MODULE cpoint
SECTION code_graphics
PUBLIC _cpoint
EXTERN bc__graphics_read_point

; Small-C caller-clean x,y. Return the clipped point result in L and
; zero-extend it in HL for the int API. Preserve IX/IY.
_cpoint:
        ld a,3
        jp bc__graphics_read_point
