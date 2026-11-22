        MODULE c_point
EXTERN _point
SECTION code_graphics
PUBLIC _c_point

; Small-C caller-clean x,y. Return the clipped point result in L and
; zero-extend it in HL for the int API. Preserve IX/IY.
defc _c_point = _point
