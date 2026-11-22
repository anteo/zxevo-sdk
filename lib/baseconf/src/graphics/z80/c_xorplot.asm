        MODULE c_xorplot
EXTERN _xorplot
SECTION code_graphics
PUBLIC _c_xorplot

; Small-C caller-clean x,y. Tail-enter the pixel wrapper with op in A.
defc _c_xorplot = _xorplot
